# This script list the name and version of every package installed
# as part of a given spec

# Usage :
#     spack python list-packages.py <spec>
# 
# Example:
#     // Hash of the installed package
#     spack python list-packages.py /nuba124
# 
#     // Package name and version
#     spack python list-packages.py fccdevel@1.0
#
# Output:
# 
#     tricktrack     : 1.0.5          
#     intel-tbb      : 2018_U1        
#     cmake          : 3.11.1         
#     pythia8        : 240            
#     root           : 6.14.04        
#     acts-core      : 0.07.01        
#     hepmc          : 2.06.09        
#     gaudi          : v29r2          
#     heppy          : develop        
#     papas          : 1.2.0          
#     delphes        : 3.4.2pre12     
#     dd4hep         : 01-08          
#     fastjet        : 3.3.0          
#     geant4         : 10.04.p02      
#     fcc-edm        : 0.5.2   

import sys

pkgspec = sys.argv[1]

specs = spack.cmd.parse_specs(pkgspec, concretize=True)
installed = list(filter(lambda x: x, map(spack.store.db.query_one, specs)))

if installed:
    # Select main spec
    spec = specs[0]

    pkgname = spec.package.name
    dependencies = spec.package.dependencies.keys()
    for d in dependencies:
        if d in spec:
            name = spec[d].name
            version = spec[d].version
            print("{0:15}: {1:15}".format(name, str(version)))
