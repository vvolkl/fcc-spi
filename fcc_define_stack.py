import os
import yaml
import argparse
import re
import sys

def main():
    parser = argparse.ArgumentParser("LCG packages spec creator", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('fcc_version', type=str, help='fcc stack version')
    parser.add_argument('--fcc_yaml', type=str, default='./docpage/_data/packages.yml', help='fcc yaml file')
    parser.add_argument('--base_yaml', type=str, help='Package specs on which to base the specs')
    parser.add_argument('--force_compiler', action='store_true', help='Do we constrain the compiler?')
    parser.add_argument('--out', '-o', type=str, default='fcc_packages.yaml', help='name of the output file')
    args = parser.parse_args()

    fcc_packages = {}
    lcg_version = ""
    compiler_spec = ""

    with open(args.fcc_yaml, 'r') as fobj_fcc:
        fcc_config = yaml.load(fobj_fcc)

    # the + "x" is to avoid the fact that 0.8pre > 0.8
    versions = [v["version"]+"x" for v in fcc_config]
    idx = -1
    if args.fcc_version == "latest":
        idx = versions.index(max(versions))
    else:
        if not args.fcc_version+"x" in versions:
            print "Could not find specified version (", args.fcc_version, ") in", args.fcc_yaml
            return -1
        idx = versions.index(args.fcc_version+"x")

    fcc_packages = fcc_config[idx]["packages"]
    lcg_version = fcc_config[idx]["lcg"]
    compiler_spec = fcc_config[idx]["compiler"]

    packages = {"packages":{}}
    # set up base packages
    if not args.base_yaml is None:
        with open(args.base_yaml, 'r') as fobj_lcg:
            packages = yaml.load(fobj_lcg)
        if args.force_compiler:
            packages['packages']['all'] = {'compiler': compiler_spec}

    for name, spec in fcc_packages.iteritems():
        packages['packages'][name] = spec

    with open(args.out, 'w') as fobj:
        fobj.write(yaml.dump(packages))

    return 0


if __name__ == "__main__":
    quit(main())
