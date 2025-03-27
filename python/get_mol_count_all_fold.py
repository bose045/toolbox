import os
import sys
import glob
import re
import pandas as pd


def extract_timestep(filename):
    """Extract numerical timestep from filename (assuming format gasmotion*.step)."""
    match = re.search(r'(\d+)', filename)
    return int(match.group(1)) if match else float('inf')


def parse_lammps_dump(filename):
    """Parse a LAMMPS dump file and extract timestep and atom data."""
    with open(filename, 'r') as f:
        lines = f.readlines()

    step = None
    atoms = []
    is_atom_section = False

    i = 0
    while i < len(lines):
        words = lines[i].split()

        if not words:
            i += 1
            continue

        if words[0] == "ITEM:":
            if "TIMESTEP" in lines[i]:
                # Read the next line for the timestep
                step = int(lines[i + 1].strip())
                i += 2
            elif "BOX BOUNDS" in lines[i]:
                i += 4  # Skip box bounds (3 lines + header)
            elif "ATOMS" in lines[i]:
                is_atom_section = True
                i += 1  # Move to atom data
            else:
                is_atom_section = False
                i += 1
        elif is_atom_section:
            # Ensure line has at least 7 values (id, mol, type, q, x, y, z)
            if len(words) < 7:
                print(
                    f"Warning: Skipping malformed atom line in {filename}: {lines[i].strip()}")
                i += 1
                continue
            try:
                atom_data = [
                    int(
                        words[0]), int(
                        words[1]), int(
                        words[2]), float(
                        words[3]), float(
                        words[4]), float(
                            words[5]), float(
                                words[6])]
                atoms.append(atom_data)
            except ValueError:
                print(
                    f"Warning: Skipping non-numeric atom line in {filename}: {lines[i].strip()}")
            i += 1
        else:
            i += 1

    if step is None:
        print(f"Warning: No TIMESTEP found in {filename}")

    return step, atoms


def count_molecules(files, stride, z_min=-4, z_max=41.8):
    """Counts type 3 (CO2) and type 5 (N2) molecules inside and outside the z range."""
    results = []

    for file in sorted(
            files,
            key=extract_timestep)[
            ::stride]:  # Sort files numerically
        step, atoms = parse_lammps_dump(file)
        if step is None or not atoms:
            print(f"Skipping file {file} due to missing step or atoms.")
            continue

        # Count type 3 (CO2) and type 5 (N2) inside and outside z range
        co2_inside = sum(
            1 for atom in atoms if atom[2] == 3 and z_min <= atom[6] <= z_max)
        n2_inside = sum(
            1 for atom in atoms if atom[2] == 5 and z_min <= atom[6] <= z_max)
        co2_botres = sum(
            1 for atom in atoms if atom[2] == 3 and atom[6] < z_min)
        n2_botres = sum(
            1 for atom in atoms if atom[2] == 5 and atom[6] < z_min)
        co2_topres = sum(
            1 for atom in atoms if atom[2] == 3 and atom[6] > z_max)
        n2_topres = sum(
            1 for atom in atoms if atom[2] == 5 and atom[6] > z_max)

        results.append([step, co2_inside, n2_inside, co2_topres,
                       n2_topres, co2_botres, n2_botres])

    return results


def process_all_subdirectories(stride):
    """Finds all subdirectories and processes each separately."""
    base_dir = os.getcwd()  # Get the current directory
    for root, dirs, files in os.walk(base_dir):
        if root == base_dir:
            continue  # Skip processing the base directory itself

        print(f"Processing folder: {root}")
        os.chdir(root)  # Change to subdirectory

        files = glob.glob("gasmotion*")
        if not files:
            print(
                f"No files matching 'gasmotion*' found in {root}. Skipping...")
            continue

        data = count_molecules(files, stride)

        if data:
            df = pd.DataFrame(
                data,
                columns=[
                    "Step",
                    "CO2 Inside Count",
                    "N2 Inside Count",
                    "CO2 Topres Count",
                    "N2 Topres Count",
                    "CO2 Botres Count",
                    "N2 Botres Count"])
            df = df.sort_values(by="Step")  # Ensure final sorting
            output_file = os.path.join(root, "molecule_counts.csv")
            df.to_csv(output_file, index=False)
            print(f"Results saved in {output_file}")
        else:
            print(f"No valid data extracted in {root}.")

        os.chdir(base_dir)  # Return to base directory


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python count_molecules.py <stride>")
        sys.exit(1)

    stride = int(sys.argv[1])

    process_all_subdirectories(stride)
