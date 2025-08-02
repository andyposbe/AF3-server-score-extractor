#!/bin/bash

# Create a temporary Python script
PYTHON_SCRIPT="af3_analysis.py"

# Generate Python script
cat << 'EOF' > $PYTHON_SCRIPT
#!/usr/bin/env python3
"""
AF3 Analysis Script
Analyzes AlphaFold 3 results, generating PAE thumbnails and Excel reports with confidence metrics.

Compatible with Windows, macOS, and Linux.
"""

import sys
import os
import json
import re
import platform
from pathlib import Path

def check_required_libraries():
    """Check if all required libraries are installed"""
    required_libraries = {
        'numpy': 'numpy',
        'matplotlib': 'matplotlib', 
        'pandas': 'pandas',
        'xlsxwriter': 'xlsxwriter'
    }
    
    missing_libraries = []
    
    print("Checking required libraries...")
    for lib_name, import_name in required_libraries.items():
        try:
            __import__(import_name)
            print(f"✓ {lib_name} is installed")
        except ImportError:
            missing_libraries.append(lib_name)
            print(f"✗ {lib_name} is NOT installed")
    
    if missing_libraries:
        print("\n" + "="*60)
        print("ERROR: Missing required libraries!")
        print("="*60)
        print("\nThe following libraries need to be installed:")
        for lib in missing_libraries:
            print(f"  - {lib}")
        
        print("\nTo install missing libraries, run one of these commands:")
        print("\nOption 1 - Install individually:")
        for lib in missing_libraries:
            print(f"  pip install {lib}")
        
        print(f"\nOption 2 - Install all at once:")
        print(f"  pip install {' '.join(missing_libraries)}")
        
        print(f"\nOption 3 - If using conda:")
        print(f"  conda install {' '.join(missing_libraries)}")
        
        print("\nNote: If you're using a virtual environment, make sure it's activated first.")
        print("After installation, run this script again.")
        print("="*60)
        
        sys.exit(1)
    
    print("\n✓ All required libraries are installed!")
    print("Proceeding with AF3 analysis...\n")

def clean_filename(filename):
    """Clean filename to be compatible with all operating systems"""
    # Remove or replace characters that are problematic on Windows
    if platform.system() == "Windows":
        # Windows has more restrictive rules
        filename = re.sub(r'[<>:"/\\|?*]', '_', filename)
        # Remove trailing periods and spaces
        filename = filename.rstrip('. ')
        # Ensure it's not too long (Windows path limit)
        if len(filename) > 100:
            filename = filename[:100]
    else:
        # Unix-like systems are more permissive, but still clean up
        filename = re.sub(r'[<>:"/\\|?*]', '_', filename)
    
    # Ensure the filename is not empty
    if not filename or filename.isspace():
        filename = "AF3_analysis"
    
    return filename

def parse_model_name(model_dir):
    """Extract base model name and seed from directory name"""
    # Look for pattern ending with _s followed by number
    if '_s' in model_dir:
        parts = model_dir.rsplit('_s', 1)
        if len(parts) == 2 and parts[1].isdigit():
            return parts[0], f"s{parts[1]}"
    return model_dir, "s0"  # Default to s0 if no seed found

def calculate_stats(values):
    """Calculate min, max, median, mean, and std dev for a list of values"""
    import statistics
    
    if not values or all(v == "N/A" for v in values):
        return ["N/A"] * 5
    
    # Filter out N/A values and convert to float
    numeric_values = []
    for v in values:
        if v != "N/A":
            try:
                if isinstance(v, bool):
                    numeric_values.append(float(v))
                else:
                    numeric_values.append(float(v))
            except (ValueError, TypeError):
                continue
    
    if not numeric_values:
        return ["N/A"] * 5
    
    try:
        min_val = min(numeric_values)
        max_val = max(numeric_values)
        median_val = statistics.median(numeric_values)
        mean_val = statistics.mean(numeric_values)
        std_val = statistics.stdev(numeric_values) if len(numeric_values) > 1 else 0
        return [min_val, max_val, median_val, mean_val, std_val]
    except:
        return ["N/A"] * 5

def main():
    """Main analysis function"""
    # Run the library check first
    check_required_libraries()

    # Import libraries after checking they're available
    import numpy as np
    import matplotlib.pyplot as plt
    import pandas as pd
    import xlsxwriter
    from collections import defaultdict

    # Use pathlib for cross-platform path handling
    base_dir = Path.cwd()
    dir_name = base_dir.name

    # Clean the directory name for use in filename
    clean_dir_name = clean_filename(dir_name)

    # Define output Excel file with directory name
    excel_filename = f"AF3_analysis_{clean_dir_name}.xlsx"
    excel_path = base_dir / excel_filename

    print(f"Running on: {platform.system()} {platform.release()}")
    print(f"Python version: {sys.version}")
    print(f"Working directory: {base_dir}")
    print(f"Creating analysis file: {excel_filename}")

    # Lists and dictionaries to store data
    data = []
    grouped_data = defaultdict(lambda: defaultdict(dict))

    print("\nScanning directories for AF3 results...")

    # Process each subdirectory
    for subdir_path in sorted(base_dir.iterdir()):
        if subdir_path.is_dir() and not subdir_path.name.startswith('.'):
            subdir = subdir_path.name
            json_file = None
            conf_file = None
            cif_file = None

            # Search for required files
            for file_path in subdir_path.iterdir():
                filename = file_path.name
                if filename.endswith("_full_data_0.json") and "0" in filename:
                    json_file = file_path
                    
                    # Construct the corresponding CIF file name
                    cif_filename = filename.replace("_full_data_0.json", "_model_0.cif")
                    potential_cif_path = subdir_path / cif_filename
                    if potential_cif_path.exists():
                        cif_file = potential_cif_path
                        
                elif filename.endswith("_summary_confidences_0.json") and "0" in filename:
                    conf_file = file_path

            if json_file and conf_file:
                print(f"  Processing: {subdir}")
                
                try:
                    # Load PAE data
                    with open(json_file, "r", encoding='utf-8') as f:
                        data_json = json.load(f)

                    # Load confidence metrics
                    with open(conf_file, "r", encoding='utf-8') as f:
                        conf_json = json.load(f)

                    # Extract PAE matrix
                    if "pae" in data_json:
                        pae_matrix = np.array(data_json["pae"])

                        # Generate thumbnail
                        thumbnail_path = subdir_path / "pae_thumbnail.png"
                        
                        # Create figure with proper backend handling
                        plt.ioff()  # Turn off interactive mode for better compatibility
                        fig, ax = plt.subplots(figsize=(2, 2), dpi=100)
                        ax.imshow(pae_matrix, cmap="coolwarm", interpolation="nearest")
                        ax.set_xticks([])
                        ax.set_yticks([])
                        
                        # Save with error handling
                        try:
                            plt.savefig(thumbnail_path, bbox_inches="tight", pad_inches=0.1, dpi=100)
                        except Exception as e:
                            print(f"    Warning: Could not save thumbnail for {subdir}: {e}")
                            thumbnail_path = None
                        finally:
                            plt.close(fig)

                        # Extract confidence metrics
                        iptm = conf_json.get("iptm", "N/A")
                        ptm = conf_json.get("ptm", "N/A")
                        ranking_score = conf_json.get("ranking_score", "N/A")
                        num_recycles = conf_json.get("num_recycles", "N/A")
                        fraction_disordered = conf_json.get("fraction_disordered", "N/A")
                        has_clash = conf_json.get("has_clash", "N/A")
                        chain_iptm = str(conf_json.get("chain_iptm", "N/A"))
                        chain_pair_iptm = str(conf_json.get("chain_pair_iptm", "N/A"))
                        chain_pair_pae_min = str(conf_json.get("chain_pair_pae_min", "N/A"))
                        chain_ptm = str(conf_json.get("chain_ptm", "N/A"))

                        # Store data
                        data.append([
                            subdir, 
                            str(cif_file) if cif_file else "N/A", 
                            str(thumbnail_path) if thumbnail_path else "N/A", 
                            iptm, ptm, ranking_score, num_recycles,
                            fraction_disordered, has_clash, chain_iptm, chain_pair_iptm,
                            chain_pair_pae_min, chain_ptm
                        ])

                        # Group data for seed analysis
                        base_model, seed = parse_model_name(subdir)
                        grouped_data[base_model][seed] = {
                            'iptm': iptm,
                            'ptm': ptm,
                            'fraction_disordered': fraction_disordered,
                            'has_clash': has_clash
                        }

                except Exception as e:
                    print(f"    Error processing {subdir}: {e}")
                    continue

    print(f"\nProcessing complete! Found {len(data)} models to process.")

    if not data:
        print("No AF3 data found. Please ensure you're running this script in a directory containing AF3 results.")
        sys.exit(1)

    # Analyze seed distribution
    print("\nSeed Analysis:")
    print("="*50)

    # Build headers for second worksheet - dynamically detect all seeds
    all_seeds = set()
    for base_model, seeds_data in grouped_data.items():
        all_seeds.update(seeds_data.keys())

    sorted_seeds = sorted(all_seeds)
    num_seeds = len(sorted_seeds)

    print(f"Detected {num_seeds} unique seeds: {', '.join(sorted_seeds)}")

    # Show distribution of seeds per base model
    seed_distribution = {}
    for base_model, seeds_data in grouped_data.items():
        num_model_seeds = len(seeds_data)
        if num_model_seeds not in seed_distribution:
            seed_distribution[num_model_seeds] = 0
        seed_distribution[num_model_seeds] += 1

    print(f"Seed distribution across {len(grouped_data)} base models:")
    for num_seeds_per_model, count in sorted(seed_distribution.items()):
        print(f"  - {count} model(s) with {num_seeds_per_model} seed(s)")

    if len(seed_distribution) > 1:
        print("\nNote: Models have different numbers of seeds. Missing seeds will show 'N/A' in the analysis.")

    print("="*50)

    # Create Excel file
    try:
        workbook = xlsxwriter.Workbook(str(excel_path))
    except Exception as e:
        print(f"Error creating Excel file: {e}")
        sys.exit(1)

    # Create formats
    center_format = workbook.add_format({'align': 'center', 'valign': 'vcenter'})
    header_format = workbook.add_format({'align': 'center', 'valign': 'vcenter', 'bold': True})
    left_format = workbook.add_format({'align': 'left', 'valign': 'vcenter'})
    left_header_format = workbook.add_format({'align': 'left', 'valign': 'vcenter', 'bold': True})

    # Create first worksheet (all data)
    worksheet1 = workbook.add_worksheet("All data")

    # Define column sizes
    worksheet1.set_column("A:A", 50)  # Model Name
    worksheet1.set_column("B:B", 20)  # PAE
    worksheet1.set_column("C:C", 40)  # Path
    worksheet1.set_column("D:D", 12)  # iPTM
    worksheet1.set_column("E:E", 12)  # PTM
    worksheet1.set_column("F:F", 15)  # Ranking Score
    worksheet1.set_column("G:G", 15)  # Num Recycles
    worksheet1.set_column("H:H", 18)  # Fraction Disordered
    worksheet1.set_column("I:I", 12)  # Has Clash
    worksheet1.set_column("J:J", 15)  # Chain iPTM
    worksheet1.set_column("K:K", 18)  # Chain Pair iPTM
    worksheet1.set_column("L:L", 20)  # Chain Pair PAE Min
    worksheet1.set_column("M:M", 15)  # Chain PTM

    # Set row height
    row_height = 45
    for row in range(1, len(data) + 1):
        worksheet1.set_row(row, row_height)

    # Write headers
    headers = [
        "Model", "PAE", "Path", "iPTM", "PTM", "Ranking Score", "Num Recycles",
        "Fraction Disordered", "Has Clash", "Chain iPTM", "Chain Pair iPTM",
        "Chain Pair PAE Min", "Chain PTM"
    ]
    for col, header in enumerate(headers):
        if header in ["Model", "Path"]:
            worksheet1.write(0, col, header, left_header_format)
        else:
            worksheet1.write(0, col, header, header_format)

    # Insert data
    for row, (
        model, cif_path, img_path, iptm, ptm, ranking_score, num_recycles, fraction_disordered,
        has_clash, chain_iptm, chain_pair_iptm, chain_pair_pae_min, chain_ptm
    ) in enumerate(data, start=1):
        worksheet1.write(row, 0, model, left_format)
        worksheet1.write(row, 2, cif_path, left_format)
        worksheet1.write(row, 3, iptm, center_format)
        worksheet1.write(row, 4, ptm, center_format)
        worksheet1.write(row, 5, ranking_score, center_format)
        worksheet1.write(row, 6, num_recycles, center_format)
        worksheet1.write(row, 7, fraction_disordered, center_format)
        worksheet1.write(row, 8, has_clash, center_format)
        worksheet1.write(row, 9, chain_iptm, center_format)
        worksheet1.write(row, 10, chain_pair_iptm, center_format)
        worksheet1.write(row, 11, chain_pair_pae_min, center_format)
        worksheet1.write(row, 12, chain_ptm, center_format)

        # Embed image if it exists
        if img_path != "N/A" and Path(img_path).exists():
            try:
                worksheet1.insert_image(row, 1, img_path, {
                    "x_scale": 0.3, "y_scale": 0.3,
                    "object_position": 1
                })
            except Exception as e:
                print(f"    Warning: Could not insert image for {model}: {e}")

    print("✓ First worksheet (All data) created successfully!")

    # Create second worksheet (seed analysis) if we have grouped data
    if grouped_data and sorted_seeds:
        worksheet2 = workbook.add_worksheet("Seed Analysis")

        # Set up columns
        worksheet2.set_column("A:A", 50)  # Model name
        total_cols_needed = 1  # Model column
        parameters = ["iPTM", "pTM", "FractionDisordered", "HasClash"]
        for param in parameters:
            total_cols_needed += len(sorted_seeds)  # Individual seed columns
            total_cols_needed += 5  # Statistics columns

        # Set column widths
        for col in range(1, total_cols_needed):
            worksheet2.set_column(col, col, 12)

        # Create headers
        headers2 = ["Model"]
        for param in parameters:
            for seed in sorted_seeds:
                headers2.append(f"{param} {seed}")
            headers2.extend([f"{param} Min", f"{param} Max", f"{param} Median", f"{param} Mean", f"{param} SD"])

        print(f"✓ Creating seed analysis with {len(sorted_seeds)} seeds and {len(headers2)} columns")

        # Write headers
        for col, header in enumerate(headers2):
            if header == "Model":
                worksheet2.write(0, col, header, left_header_format)
            else:
                worksheet2.write(0, col, header, header_format)

        # Write data
        row = 1
        for base_model in sorted(grouped_data.keys()):
            seeds_data = grouped_data[base_model]
            worksheet2.write(row, 0, base_model, left_format)
            
            col = 1
            for param_key, param_name in [("iptm", "iPTM"), ("ptm", "pTM"), 
                                          ("fraction_disordered", "FractionDisordered"), 
                                          ("has_clash", "HasClash")]:
                # Write individual seed values
                values = []
                for seed in sorted_seeds:
                    if seed in seeds_data and param_key in seeds_data[seed]:
                        value = seeds_data[seed][param_key]
                        worksheet2.write(row, col, value, center_format)
                        values.append(value)
                    else:
                        worksheet2.write(row, col, "N/A", center_format)
                        values.append("N/A")
                    col += 1
                
                # Calculate and write statistics
                stats = calculate_stats(values)
                for stat in stats:
                    worksheet2.write(row, col, stat, center_format)
                    col += 1
            
            row += 1

        print("✓ Second worksheet (Seed Analysis) created successfully!")
    else:
        print("⚠ No seed analysis data found - skipping second worksheet")

    # Save and close workbook
    workbook.close()

    print(f"\n✓ Excel file created: {excel_filename}")
    print(f"✓ First tab: All data ({len(data)} models)")
    if grouped_data:
        print(f"✓ Second tab: Seed analysis ({len(grouped_data)} base models, {len(sorted_seeds)} seeds)")
    print("\nAnalysis complete!")

if __name__ == "__main__":
    main()
EOF

# Check if Python 3 is available
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo "Error: Python is not installed or not in PATH"
    echo "Please install Python 3.7 or higher"
    exit 1
fi

echo "AF3 Analysis Tool"
echo "================"
echo "Using Python: $PYTHON_CMD"

# Run Python script
$PYTHON_CMD $PYTHON_SCRIPT

# Get the exit code
EXIT_CODE=$?

# Clean up
rm $PYTHON_SCRIPT

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "AF3 analysis completed successfully!"
else
    echo ""
    echo "AF3 analysis encountered an error (exit code: $EXIT_CODE)"
fi

exit $EXIT_CODE