#!/usr/bin/env python3
"""
Microtool: find_residue_numbers

Description:
    This tool finds all unique residue numbers in a PDB file corresponding to a specified amino acid.

Usage:
    python find_residue_numbers.py <pdb_file> <resname>

Example:
    python find_residue_numbers.py protein.pdb ASP
"""

import sys

def find_residue_numbers(pdb_file: str, target_resname: str) -> list:
    """
    Extracts residue numbers matching a given amino acid from a PDB file.

    Args:
        pdb_file (str): Path to the PDB file.
        target_resname (str): Amino acid 3-letter code (e.g., 'GLY', 'ASP').

    Returns:
        List[int]: Sorted list of unique residue numbers.
    """
    residue_numbers = set()

    with open(pdb_file, 'r') as f:
        for line in f:
            if line.startswith("ATOM"):
                resname = line[17:20].strip()
                resnum = int(line[22:26])
                if resname == target_resname:
                    residue_numbers.add(resnum)

    return sorted(residue_numbers)

def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)

    pdb_path = sys.argv[1]
    resname = sys.argv[2].upper()

    residue_ids = find_residue_numbers(pdb_path, resname)

    if residue_ids:
        print(f"Residue numbers for {resname}: {residue_ids}")
    else:
        print(f"No residues found for amino acid: {resname}")

if __name__ == "__main__":
    main()

