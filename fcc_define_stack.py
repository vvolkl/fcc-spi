import os
import yaml
import argparse
import re

def main():
    parser = argparse.ArgumentParser("LCG packages spec creator", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('fcc_yaml', type=str, help='fcc yaml file')
    parser.add_argument('fcc_version', type=str, help='fcc stack version')
    parser.add_argument('--lcg_yaml', type=str, help='LCG yaml file')
    parser.add_argument('--out', '-o', type=str, default='fcc_packages.yaml', help='name of the output file')
    parser.add_argument('--dockerfile', type=str, help='create spec for this docker image (does not use lcg packages)')
    args = parser.parse_args()
    ubuntu_to_spack_dict = {
        "libncurses5": "curses",
        "zlib1g-dev": "zlib",
        "python-yaml": "py-pyyaml"
    }

    fcc_packages = {}
    lcg_version = ""
    compiler_spec = ""
    with open(args.fcc_yaml, 'r') as fobj_fcc:
        fcc_config = yaml.load(fobj_fcc)
        for v in fcc_config:
            if v['version'] == args.fcc_version:
                fcc_packages = v["packages"]
                lcg_version = v["lcg"]
                compiler_spec = v["compiler"]

    if lcg_version == "":  # arbitrary which of the extracted variables we check!
        print "Could not find specified version (", args.fcc_version, ") in", args.fcc_yaml

    packages = {"packages":{}}
    # set up lcg packages
    if not args.lcg_yaml is None:
        with open(args.lcg_yaml, 'r') as fobj_lcg:
            packages = yaml.load(fobj_lcg)

    for name, spec in fcc_packages.iteritems():
        packages['packages'][name] = spec

    # on machines using lcg packages, ensure we are using the right compiler:
    if args.dockerfile is None:
        packages['packages']['all'] = {'compiler': compiler_spec}
    else:
        # in the docker we can use some pre-built ubuntu packages to speed up bootstrap:
        package_names = ["openssl", "libncurses5"]  # installed by default
        with open(args.dockerfile, 'r') as fobj:
            for line in fobj:
                if line.startswith("RUN apt-get") and "install" in line:
                    fragments = line.split()
                    if "install" in fragments:
                        # skip install and -y
                        package_names += fragments[fragments.index("install")+2:]
        for package in package_names:
            spack_name = package
            if package in ubuntu_to_spack_dict.keys():
                ubuntu_to_spack_dict[package]
            packages['packages'][spack_name] = {"buildable": False, "paths": {spack_name:"/usr/"}}


    with open(args.out, 'w') as fobj:
        fobj.write(yaml.dump(packages))


if __name__ == "__main__":
    main()
