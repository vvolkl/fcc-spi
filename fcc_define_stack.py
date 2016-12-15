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
    args = parser.parse_args()


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
        packages['packages']['all'] = {'compiler': compiler_spec}
    else:
        package_names = ["openssl", "python"]  # installed by default
        for package in package_names:
            spack_name = package
            packages['packages'][spack_name] = {"buildable": False, "paths": {spack_name:"/usr/"}}

    for name, spec in fcc_packages.iteritems():
        packages['packages'][name] = spec

    with open(args.out, 'w') as fobj:
        fobj.write(yaml.dump(packages))


if __name__ == "__main__":
    main()
