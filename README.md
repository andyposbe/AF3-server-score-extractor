# AF3 Server Score Extractor

<a href="https://doi.org/10.5281/zenodo.17136186"><img src="https://zenodo.org/badge/1030846902.svg" alt="DOI"></a>

Tool for analyzing AlphaFold 3 results, generating PAE visualizations and Excel reports with confidence metrics.


---

## Overview

This tool processes AF3 output files to create comprehensive analysis reports including PAE thumbnails, confidence metrics, and statistical comparisons across multiple seeds.

---

## Installation

### Requirements

- Python 3.7+
- `numpy`, `matplotlib`, `pandas`, `xlsxwriter`

### Quick Install

```bash
git clone https://github.com/andyposbe/AF3-server-score-extractor.git
cd AF3-server-score-extractor
pip install -r requirements.txt
```

---

## Usage

Navigate to your AF3 results directory and run:

```bash
# Using the bash script (recommended)
bash /path/to/AF3_score_extractor.sh

# Or run Python directly
python /path/to/af3_analysis.py
```

---

## Input Structure

The tool expects AF3 results organized in subdirectories like this:

```
your_af3_results/
├── model1_s1/
│   ├── fold_model1_s1_full_data_0.json
│   ├── fold_model1_s1_summary_confidences_0.json
│   └── fold_model1_s1_model_0.cif
├── model1_s2/
│   ├── fold_model1_s2_full_data_0.json
│   ├── fold_model1_s2_summary_confidences_0.json
│   └── fold_model1_s2_model_0.cif
└── ...
```

### Required Files per Model

- `*_full_data_0.json` – Contains PAE matrix data  
- `*_summary_confidences_0.json` – Contains confidence metrics  
- `*_model_0.cif` – Structure file (for path reference)

---

## Output

### 1. Excel Report (`AF3_analysis_[directory_name].xlsx`)

- **Tab 1: All Data**
  - Individual model results with embedded PAE thumbnails
  - Complete confidence metrics for each model
  - File paths for structure reference

- **Tab 2: Seed Analysis** (if multiple seeds detected)
  - Statistical summary across seeds (min, max, median, mean, std)
  - Automatically handles any number of seeds

### 2. PAE Thumbnails

- `pae_thumbnail.png` files generated in each model directory
- Heatmap visualizations of predicted aligned error matrices

---

## Supported Metrics

| Metric                 | Description                                      |
|------------------------|--------------------------------------------------|
| iPTM                  | Interface Predicted Template Matching score       |
| pTM                   | Predicted Template Matching score                 |
| Ranking Score         | AlphaFold 3 Confidence Ranking                    |
| Num Recycles          | Number of recycling iterations used               |
| Fraction Disordered   | Proportion of disordered regions                  |
| Has Clash             | Structural clash detection (True/False)           |
| Chain iPTM            | Chain-specific iPTM values                        |
| Chain Pair iPTM       | Inter-chain iPTM values                           |
| Chain Pair PAE Min    | Minimum PAE between chain pairs                   |
| Chain pTM             | Chain-specific pTM values                         |

---

## Cross-Platform Compatibility

- **Windows**: Use `AF3_score_extractor.bat` or run Python directly  
- **macOS/Linux**: Use `bash AF3_score_extractor.sh`  
- **All platforms**: Direct Python execution (`python af3_analysis.py`)

---

## Features

- Automatic library dependency checking with installation guidance
- Dynamic seed detection
- Cross-platform path handling
- Robust error handling and progress reporting
- Professional Excel formatting with embedded images
- Statistical analysis with publication-ready metrics

---

## Troubleshooting

### Common Issues

**"No AF3 data found"**
- Ensure you're in the correct directory
- Verify subdirectories contain the required JSON and CIF files

**"Missing required libraries"**
- Run the installation commands provided
- Use a virtual environment if needed

**Permission errors**
- Check write permissions in target directory
- On Unix systems, run `chmod +x AF3_score_extractor.sh`

---

## Example Output Structure

```
your_af3_results/
├── model1_s1/
│   ├── fold_model1_s1_full_data_0.json
│   ├── fold_model1_s1_summary_confidences_0.json
│   ├── fold_model1_s1_model_0.cif
│   └── pae_thumbnail.png        # Generated
├── model1_s2/ ...
└── AF3_analysis_your_af3_results.xlsx  # Generated
```

---

## License

MIT License – see [`LICENSE`](LICENSE) file for details.

---

## Citation

If you use this tool in your research, please cite:

```bibtex
@software{andres_posbeyikian_2025_17136187,
  author       = {Andres Posbeyikian},
  title        = {andyposbe/AF3-server-score-extractor: Latest
                   Release
                  },
  month        = sep,
  year         = 2025,
  publisher    = {Zenodo},
  version      = {v1.0.0},
  doi          = {10.5281/zenodo.17136187},
  url          = {https://doi.org/10.5281/zenodo.17136187},
  swhid        = {swh:1:dir:62f972cf7691f14e442a231d29c237901e32f546
                   ;origin=https://doi.org/10.5281/zenodo.17136186;vi
                   sit=swh:1:snp:50239e5b0f4d2ecced5ed3aeddce3b301b90
                   a1d5;anchor=swh:1:rel:4689def25d5140be6c833976568a
                   4a709072408a;path=andyposbe-AF3-server-score-
                   extractor-300fca0
                  },
}

```

If you use the AF3 server to generate your results, please reference:
Abramson, J et al. Accurate structure prediction of biomolecular interactions with AlphaFold 3. Nature (2024)

---

## Contributing

Contributions are welcome. Please submit issues and pull requests through GitHub.

---

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/af3-analysis-tool/issues)
- **Documentation**: See repository wiki for detailed examples
