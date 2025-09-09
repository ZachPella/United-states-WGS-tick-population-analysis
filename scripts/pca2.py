# Install required packages in Colab if not already installed
# You can uncomment the line below to install them
# !pip install openpyxl seaborn

# Import necessary libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Set a style for better looking plots
plt.style.use('default')

# --- File Paths ---
# Update these paths if your files are in a different location
tick_file = "/content/tick.xlsx"
eigenval_file = "/content/eigenval.xlsx"
metadata_file = "colors.xlsx"

def load_and_prepare_data(tick_path, eigenval_path, metadata_path):
    """
    Loads PCA data, eigenvalues, and metadata from Excel files,
    then merges and prepares the data for plotting.

    Args:
        tick_path (str): Path to the PCA scores (tick.xlsx).
        eigenval_path (str): Path to the eigenvalues (eigenval.xlsx).
        metadata_path (str): Path to the sample metadata (colors.xlsx).

    Returns:
        tuple: A tuple containing:
            - pca_with_meta (pd.DataFrame): Merged DataFrame with PCA scores and metadata.
            - pve (np.array): Percentage of variance explained by each PC.
    """
    # Load PCA scores and eigenvalues
    pca_scores = pd.read_excel(tick_path)
    eigenval_df = pd.read_excel(eigenval_path)
    eigenval = eigenval_df.iloc[:, 0].values
    pve = (eigenval / eigenval.sum()) * 100

    # Extract PC columns and rename 'Sample' to 'ind'
    pc_columns = [col for col in pca_scores.columns if col.startswith('PC')]
    pca_data = pca_scores[['Sample'] + pc_columns].rename(columns={'Sample': 'ind'})

    # Load and process metadata
    metadata = pd.read_excel(metadata_path)

    def assign_group(row):
        if row['State'] == 'Nebraska':
            return row['County'] if pd.notna(row['County']) else 'Nebraska'
        else:
            return row['State']

    metadata['Location_Group'] = metadata.apply(assign_group, axis=1)
    
    pca_with_meta = pca_data.merge(metadata[['Sample', 'Location_Group']],
                                   left_on='ind', right_on='Sample', how='left')
    return pca_with_meta, pve

def plot_pca(pca_data, pve, pc1=1, pc2=2):
    """
    Creates and displays a PCA plot for two specified principal components.

    Args:
        pca_data (pd.DataFrame): DataFrame with PCA scores and location groups.
        pve (np.array): Percentage of variance explained.
        pc1 (int): The number of the first principal component to plot (e.g., 1).
        pc2 (int): The number of the second principal component to plot (e.g., 2).
    """
    plt.figure(figsize=(14, 10))
    
    midwest_east_states = ['Iowa', 'Minnesota', 'Wisconsin', 'Michigan', 'Maine', 'Maryland']
    southern_states = ['Florida', 'Virginia', 'North Carolina', 'South Carolina', 'Alabama', 'Tennessee', 'Texas', 'Oklahoma', 'Kansas']
    
    nebraska_county_colors = {
        'Thurston': '#00BFFF',
        'Dodge': '#FF4500',
        'Sarpy': '#DA70D6',
        'Douglas': '#32CD32'
    }
    
    label_map = {
        'Thurston': 'Nebraska (Thurston county)',
        'Dodge': 'Nebraska (Dodge county)',
        'Sarpy': 'Nebraska (Sarpy county)',
        'Douglas': 'Nebraska (Douglas county)',
        'South Carolina': 'S. Carolina',
        'North Carolina': 'N. Carolina'
    }

    present_groups = sorted(pca_data['Location_Group'].dropna().unique())

    for group in present_groups:
        group_data = pca_data[pca_data['Location_Group'] == group]
        if not group_data.empty:
            
            if group in midwest_east_states:
                color = 'black'
                edgecolors = 'black'
            elif group in southern_states:
                color = 'white'
                edgecolors = 'black'
            elif group in nebraska_county_colors:
                color = nebraska_county_colors[group]
                edgecolors = 'black'
            else:
                color = 'gray'
                edgecolors = 'black'

            label = label_map.get(group, group)
            label = f'{label} (n={len(group_data)})'
            
            plt.scatter(group_data[f'PC{pc1}'], group_data[f'PC{pc2}'],
                        c=color, label=label, s=80, alpha=0.85,
                        edgecolors=edgecolors, linewidth=1.5)

    plt.xlabel(f'PC{pc1} ({pve[pc1-1]:.1f}%)', fontsize=14, fontweight='bold')
    plt.ylabel(f'PC{pc2} ({pve[pc2-1]:.1f}%)', fontsize=14, fontweight='bold')
    plt.title('PCA Plot - I. scapularis Population Structure', fontsize=16, fontweight='bold')

    if len(present_groups) > 8:
        plt.legend(title='Location', title_fontsize=12, fontsize=10,
                   bbox_to_anchor=(1.05, 1), loc='upper left')
    else:
        plt.legend(title='Location', title_fontsize=12, fontsize=11, loc='upper right')

    plt.grid(True, alpha=0.3)
    plt.axis('equal')
    plt.tight_layout()
    plt.show()

    print("\nSample distribution by state:")
    print("-" * 30)
    state_counts = pca_data['Location_Group'].value_counts().sort_index()
    for state, count in state_counts.items():
        print(f"{state}: {count} samples")
    print(f"\nTotal samples: {len(pca_data)}")

if __name__ == "__main__":
    try:
        pca_with_meta, pve = load_and_prepare_data(tick_file, eigenval_file, metadata_file)
        plot_pca(pca_with_meta, pve)

    except FileNotFoundError as e:
        print(f"Error: Could not find file - {e.filename}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
