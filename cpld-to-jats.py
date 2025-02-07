import click
from pathlib import Path
import os
from cpld2jats import convert

@click.command()
@click.argument('PATHS', required=True, nargs=-1, type=click.Path(exists=True))
@click.option('--destination', default="jats", help='The destination path for the JATS output files, defaulting to `jats` ')
@click.option('--relative/--absolute', default=True, help='Create the destination path relative to each source file (default) or create it as is.')
@click.option('--embed/--link', default=True, help='Embed the JSON-LD output inside the HTML file (default) or only link to it.')
@click.option('--overwrite/--skip-existing', default=False, help='Skip existing files (default) or overwrite files without asking.')
def cli_convert(paths, destination, relative, embed, overwrite):
    """cpld-to-jats.py PATHS
    
    Convert al files in PATHS from CP/LD to JATS XML,
    and write them to a destination folder ('jats' by default)
    """
    for cpld_file in paths:
        cpld_path = Path(cpld_file)
        cpld_path_stem = cpld_path.stem # The stem of the filename identified by the path (i.e. the filename without the final extension).

        if relative:
            destination_path = cpld_path.parent.joinpath(Path(destination))
        else:
            destination_path = Path(destination)
        
        # Create the destination if it doesn't already exist.
        destination_path.mkdir(parents=True, exist_ok=True)

        jats_path = destination_path.joinpath(cpld_path_stem + '.xml')
        # Assuming for now that the JSON-LD file will have the same stem as the HTML file.
        jsonld_path = destination_path.joinpath(cpld_path_stem + '.jsonld')
        if not overwrite and jats_path.exists:
            print(f"Destination JATS XML file {jats_path} already exists. Continuing will overwrite the existing file.")
            if not click.confirm('Do you want to continue?'):
                print(f"Skipping conversion of {cpld_path}")
                continue







        print(f"Converting {cpld_path} to destination {destination_path}")
        convert.convert_from_file(cpld_path, jats_path, jsonld_path, embed=embed)

        print(f"... done")


    
if __name__ == '__main__':
    cli_convert()
