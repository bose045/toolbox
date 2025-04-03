import os
import numpy as np
from collections import defaultdict

def extract_numbers(pair):
    """
    Extract numeric parts from pair labels (e.g., 'r_12') for sorting.
    Returns a tuple of integers.
    """
    return tuple(int(x.split('_')[1]) for x in pair)

def write_output(data_dict, filename, label):
    """
    Writes the processed data for an experiment to a file.
    The file includes the residue pair and the mean and standard deviation of the values.
    """
    sorted_data = sorted(data_dict.items(), key=lambda item: extract_numbers(item[0]))
    with open(filename, "w") as out_file:
        out_file.write("res-01 res-02 G_mean G_std\n")
        for pair, values in sorted_data:
            mean_value = np.mean(values)
            std_value = np.std(values, ddof=1)
            out_file.write(f"{pair[0]} {pair[1]} {mean_value:.6f} {std_value:.6f}\n")
    print(f"{label} results written to {filename}")

def main():
    # Ask user for the range of run folders.
    start_input = input("Enter starting run index (default 1): ").strip()
    start = int(start_input) if start_input else 1

    end_input = input("Enter ending run index (default 100): ").strip()
    end = int(end_input) if end_input else 100

    # Generate run directories: "run_1", "run_2", ..., "run_end"
    run_dirs = [f"run_{i}" for i in range(start, end + 1)]
    print("Processing the following run directories:")
    print(run_dirs)

    # Ask for the default experiment definition.
    default_exp = input("Enter default experiment definition (format Label:subfolder) [default: Base:]: ").strip()
    if default_exp:
        if ':' in default_exp:
            default_label, default_subfolder = default_exp.split(":", 1)
            experiments = {default_label.strip(): default_subfolder.strip()}
        else:
            experiments = {default_exp.strip(): ""}
    else:
        experiments = {"Base": ""}
    
    # Recursively ask for additional experiments.
    # Expect input in the format: Label:subfolder.
    # An empty input ends the loop.
    while True:
        exp_def = input("Enter additional experiment definition (format Label:subfolder) or press Enter to finish: ").strip()
        if not exp_def:
            break
        if ':' in exp_def:
            label, subfolder = exp_def.split(":", 1)
            experiments[label.strip()] = subfolder.strip()
        else:
            experiments[exp_def.strip()] = ""
    
    print("Experiments to process:")
    for label, subfolder in experiments.items():
        if subfolder:
            print(f"  {label}: will search for files at run_i/{subfolder}/tc.dat")
        else:
            print(f"  {label}: will search for files at run_i/tc.dat")

    # Initialize data containers and counters for each experiment.
    tc_data = {label: defaultdict(list) for label in experiments}
    file_counts = {label: 0 for label in experiments}

    # Process each run folder for each experiment.
    for run_dir in run_dirs:
        for label, subfolder in experiments.items():
            if subfolder:
                file_path = os.path.join(run_dir, subfolder, "tc.dat")
            else:
                file_path = os.path.join(run_dir, "tc.dat")
            
            if os.path.exists(file_path):
                file_counts[label] += 1
                with open(file_path, "r") as file:
                    for line in file:
                        parts = line.strip().split()
                        if len(parts) == 3:
                            pair = (parts[0], parts[1])
                            try:
                                value = float(parts[2])
                            except ValueError:
                                continue
                            tc_data[label][pair].append(value)

    # Write output files for each experiment.
    for label in experiments:
        output_filename = f"tc_mean_{label}_{file_counts[label]}_files.dat"
        write_output(tc_data[label], output_filename, label)

if __name__ == "__main__":
    main()

