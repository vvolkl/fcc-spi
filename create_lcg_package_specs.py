import os
import yaml
import argparse
import re
import glob


OS_SHORT_TO_LONG = {"slc6":"scientificcernslc6", "centos7":"centos7", "ubuntu1604":"ubuntu1604"}
virtual_packages = ['blas', 'lapack']
blacklist = ["py-pyyaml", "delphes"]

def convert_lcg_spec_file(lcg_spec, basepath, pck_dict, verbosity, limited=None):
    ''' converts lcg spec files into dict format that is expected by spack for package specs.
    each package specification looks something like this:
        cmake:
          paths:
            cmake@3.4.1%gcc@4.9.3 arch=x86_64-slc6: /afs/cern.ch/sw/lcg/releases/LCG_83/CMake/x86_64-slc6-gcc49-opt
            cmake@3.4.1%gcc@4.9.3+debug arch=x86_64-slc6: /afs/cern.ch/sw/lcg/releases/LCG_83/CMake/x86_64-slc6-gcc49-dbg
            cmake@3.4.1%gcc@4.8.3 arch=x86_64-slc6: /afs/cern.ch/sw/lcg/releases/LCG_83/CMake/x86_64-slc6-gcc48-opt
          buildable: False
    '''
    fname = lcg_spec["fname"]
    spec_template = "{pkg}@{pkg_version}%{compiler}{type} arch={arch}-{os_str}"
    spec_qualifiers = {}
    if verbosity > 1:
        print "-- parsing:", lcg_spec["type"], "built for", lcg_spec["arch"], \
              lcg_spec["os"], "with", lcg_spec["compiler"], "as", lcg_spec["build_type"]
    type_spec = ""
    if lcg_spec["build_type"] == "dbg":
        type_spec = "+debug"

    if verbosity > 0:
        print "-- (", fname, ")"
    lcg_packages = {}
    with open(fname, 'r') as fobj:
        for i, l in enumerate(fobj):
            if ":" in l:
                try:
                    attr, value = l.split(":")
                except:
                    print "Error in file: {0}\nLine: {1}".format(fname,l)
                if attr == "COMPILER":
                    cmp, ver = value.split(";")
                    value = "%s@%s" % (cmp.strip(), ver.strip())
                spec_qualifiers[attr] = value.strip()
                continue
            spec = [p.strip() for p in l.split(";")]
            pkg, sha, version, path = spec[0], spec[1], spec[2], spec[3]

            pkg_lower = pkg.lower()

            if (pkg_lower.startswith("py") or pkg_lower in ["qmtest"]) and pkg_lower not in ["pythia8", "pythia6", "python"]:
                pkg_lower = "py-" + pkg_lower
            #if pkg_lower == "pythia8":
            #    pkg_lower = "pythia"

            if pkg_lower in virtual_packages or pkg_lower in blacklist:
               continue

            spec_string = spec_template.format(pkg=pkg_lower,
                                               pkg_version=version,
                                               compiler=spec_qualifiers["COMPILER"],
                                               type=type_spec,
                                               arch=lcg_spec["arch"],
                                               os_str=OS_SHORT_TO_LONG[lcg_spec["os"]])

            pkg_path = os.path.abspath(os.path.join(basepath, path))

            # accumulate all versions of a package in the dict
            if pkg_lower not in lcg_packages.keys(): # new package
                lcg_packages[pkg_lower] = {version: (spec_string,  pkg_path)}
            else: # new version of known package
                lcg_packages[pkg_lower][version] = (spec_string,  pkg_path)

    # Prune unwanted packages:
    if limited is not None:
        unwanted_packages = [ pkg for pkg in lcg_packages.keys() if pkg not in limited]
        for pkg in unwanted_packages:
            if verbosity > 0:
                print "-- Ignoring package: %s " % pkg
            del lcg_packages[pkg]

    for pkg in lcg_packages.keys():
        # now select the highest version of each spec
        highest_version = max(lcg_packages[pkg])
        if verbosity > 2:
            print "---- selecting", highest_version, "for", pkg
        # since different OSes / compilers are in different LCG files, check:
        if not pkg in pck_dict['packages'].keys():
            pck_dict['packages'][pkg] = {"paths": {lcg_packages[pkg][highest_version][0]:
                                                   lcg_packages[pkg][highest_version][1]},
                                                    "buildable": False}
        else:
            pck_dict['packages'][pkg]["paths"][lcg_packages[pkg][highest_version][0]] = lcg_packages[pkg][highest_version][1]


def convert_lcg_contrib_file(lcg_spec, basepath, compiler_dict, verbosity):
    ''' converts lcg contrib file into dict format that is expected by spack for compiler sepcs.
    each specification looks something like this:
    - compiler:
        modules: []
        operating_system: centos6
        paths:
          cc: /path/bin/gcc
          cxx: /path/bin/g++
          f77: /path/bin/gfortran
          fc: /path/bin/gfortran
        spec: gcc@4.9.3:
    '''
    fname = lcg_spec["fname"]
    if lcg_spec["build_type"] == "dbg":
        print "-- ignoring debug contrib files (since they contain the same as opt)"
        return
    if verbosity > 1:
        print "-- parsing:", lcg_spec["type"], "built for", lcg_spec["arch"], \
              lcg_spec["os"], "with", lcg_spec["compiler"], "as", lcg_spec["build_type"]
    if verbosity > 0:
        print "-- (", fname, ")"

    compiler_list = []
    with open(fname, 'r') as fobj:
        for l in fobj:
            spec = [p.strip() for p in l.split(";")]
            compiler, sha, version, path = spec[0], spec[1], spec[2], spec[3]
            compiler_lower = compiler.lower()
            compiler_spec = {}
            compiler_spec["modules"] = []
            compiler_spec["operating_system"] = OS_SHORT_TO_LONG[lcg_spec["os"]]
            compiler_spec["paths"] = {}
            # FIXME this is for gcc, only!
            if compiler != "gcc":
                print "[WARNING] automatic compiler list gen is only enabled for gcc at the moment!"
                continue
            full_path = os.path.abspath(os.path.join(basepath, path))
            compiler_spec["paths"]["cxx"] = os.path.join(full_path, "bin/g++")
            compiler_spec["paths"]["cc"] = os.path.join(full_path, "bin/gcc")
            compiler_spec["paths"]["f77"] = os.path.join(full_path, "bin/gfortran")
            compiler_spec["paths"]["fc"] = os.path.join(full_path, "bin/gfortran")
            compiler_spec["spec"] = compiler + "@" + version
            compiler_spec["environment"] = {"set": {"LD_LIBRARY_PATH": os.path.join(full_path, "lib64")}}
            if compiler_spec["spec"] in compiler_list:
                print "warning: ", compiler_speck["spec"], "found twice, ignoring second"
                continue
            compiler_list.append(compiler_spec["spec"])
            compiler_dict["compilers"].append({"compiler": compiler_spec})


def discover_lcg_spec_files(basepath):
    '''find all LCG spec files and return list of dicts containing file info'''
    if os.path.isdir(basepath):
        fnames = os.listdir(basepath)
    else:
        fnames = glob.glob(basepath)
    # group 0 = generatros / externals / ..., group 1 = arch, group 2 = os, group 3 = compiler, group 4 = build type
    file_regex = "LCG_([a-zA-Z]+)_([a-zA-Z0-9_]+)-([a-zA-Z0-9_]+)-([a-zA-Z0-9_]+)-([a-zA-Z0-9_]+).txt$"
    lcg_spec_files = []
    lcg_contrib_files = []
    for fname in fnames:
        match = re.search(file_regex, fname)
        if not match is None and match.group(1) == "contrib":
            lcg_contrib_files.append({"fname": os.path.join(basepath, fname),
                                   "type": match.group(1),
                                   "arch": match.group(2),
                                   "os": match.group(3),
                                   "compiler": match.group(4),
                                   "build_type": match.group(5)})
        elif not match is None:
            lcg_spec_files.append({"fname": os.path.join(basepath, fname),
                                   "type": match.group(1),
                                   "arch": match.group(2),
                                   "os": match.group(3),
                                   "compiler": match.group(4),
                                   "build_type": match.group(5)})
    return lcg_spec_files, lcg_contrib_files

def get_basepath(path):
    if any([x.endswith(".txt") for x in glob.glob(path)]):
        return os.path.dirname(path)
    else:
        return path

def main():
    parser = argparse.ArgumentParser("LCG packages spec creator", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('release_path', type=str, help='LCG release path (searched for LCG_*.txt files)')
    parser.add_argument('--limited', type=str, dest='limited', nargs='*', help='List of packages to consider')
    parser.add_argument('-v', dest='verbosity', action='count', default=0, help='verbosity, max = -vvv')
    args = parser.parse_args()

    cmpnts = args.release_path.split(os.sep)
    filesystem, version = cmpnts[1], cmpnts[-2]
    basepath = get_basepath(args.release_path)

    spec_files, contrib_files = discover_lcg_spec_files(args.release_path)
    # FIXME: Need to generate a compilers file from contrib
    print "found", len(spec_files), "LCG files"
    print "Looking for a limited list: %s " % args.limited
    packages_dict = {"packages": {}}
    for spec in spec_files:
        convert_lcg_spec_file(spec, basepath, packages_dict, args.verbosity, args.limited)
    outname = version + "_packages.yaml"
    with open(outname, "w") as fobj:
        print "creating", outname
        fobj.write(yaml.dump(packages_dict))

    compilers_dict = {"compilers": []}
    for spec in contrib_files:
        convert_lcg_contrib_file(spec, basepath, compilers_dict, args.verbosity)
    outname = version + "_compilers.yaml"
    with open(outname, "w") as fobj:
        print "creating", outname
        fobj.write(yaml.dump(compilers_dict))


if __name__ == "__main__":
    main()
