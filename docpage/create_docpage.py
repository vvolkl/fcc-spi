from __future__ import print_function
import os
import time

header = """<html>
  <head>
    <title>{title}</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css"
    integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous">
  </head>
  <body>
  """
footer = """  </body>
</html>
"""
link_template = "<li><a href='{href}'>{text}</a></li>"


docdir = "/afs/cern.ch/exp/fcc/sw/documentation/"
analysisdir = "/afs/cern.ch/exp/fcc/sw/documentation/static_checks/"
translators = {"FCCSW": "FCC Core Software",
               "podio": "PODIO: Underlying Data Model library",
               "fcc-edm": "FCC Event Data Model",
               "Gaussino": "Generator and Simulation package"}


def discover_doxygens():
    """ looks for known (defined by translators) sub folders in docdir """
    content = []
    ignore = ["index.html", "links", "static_checks", "flint", "cgi-bin"]
    for dirname in os.listdir(docdir):
        if not dirname in ignore and dirname in translators.keys():
            content.append(["./{dirname}/index.html".format(dirname=dirname), translators[dirname]])
    return content


def discover_static_checks():
    """ looks for known (defined by translators) sub folders in analysisdir """
    content = []
    ignore = []
    for dirname in os.listdir(analysisdir):
        if not dirname in ignore and dirname in translators.keys():
            fulldir = analysisdir + dirname
            create_cleaned_index(fulldir+"/index.html", fulldir+"/index_short.html")
            content.append(["./static_checks/{dirname}/index.html".format(dirname=dirname), translators[dirname]])
    return content


def create_cleaned_index(fnamefull, fnamecleaned):
    """ this function creates another index for scan-build, as there seems to be no option to disallow checks of external headers"""
    with open(fnamefull, "r") as fullfile:
        with open(fnamecleaned, "w") as cleanedfile:
            for line in fullfile:
                if line.startswith('<tr class="bt__">') and not ("FCCSW" in line or "fcc-edm" in line or "podio" in line or "Gaussino" in line):
                    continue
                cleanedfile.write(line)


def main():
    statchecks = discover_static_checks()

    doxypages = discover_doxygens()
    doxypages.append(["http://test-dd4hep.web.cern.ch/test-dd4hep/doxygen/html/index.html", "DD4hep: Detector Description Toolkit"])

    # write the file...
    with open(os.path.join(docdir, "index.html"), "w") as fobj:
        fobj.write(header.format(title="FCCSW - Index"))
        fobj.write(
            "<div class='jumbotron'><div class='container'><h1>FCCSW</h1><p>Main page for documentation and resources.</p></div></div><div class='container'>")
        fobj.write("<div class='col-md-4'><h2>Documentation</h2>")
        fobj.write("<b>Doxygen:</b>")
        fobj.write("<ul>")
        for doxypage in doxypages:
            fobj.write(link_template.format(href=doxypage[0], text=doxypage[1]))
        fobj.write("</ul>")
        fobj.write("<b>Other links:</b>")

        with open(os.path.join(docdir, "links"), "r") as linkfile:
            fobj.write("<ul>")
            for line in linkfile:
                author, name, link = line.split()
                fobj.write(link_template.format(href=link, text=name.replace("_", " ")))
            fobj.write("</ul>")

        fobj.write("</div><div class='col-md-4'><h2>Other resources</h2>")
        fobj.write("<ul>")
        fobj.write(link_template.format(href="https://sft.its.cern.ch/jira/projects/FCC/", text="FCC JIRA Issue Tracker"))
        fobj.write(link_template.format(href="https://github.com/HEP-FCC/", text="FCC on GitHub"))
        fobj.write(link_template.format(href="https://phsft-jenkins.cern.ch/view/FCC/", text="FCC Continuous Integration"))
        fobj.write("</ul>")

        fobj.write("</div><div class='col-md-4'><h2>Code quality <small>experimental</small></h2>")
        fobj.write("<b>Static checks:</b>")
        fobj.write("<ul>")
        for statcheck in statchecks:
            fobj.write("<li><a href='{href_short}'>{text} (cleaned)</a><br><a href='{href_full}'>{text} (verbose)</a></li>".format(
                href_full=statcheck[0],
                href_short=statcheck[0].replace("index", "index_short"),
                text=statcheck[1]
            ))
        fobj.write(link_template.format(href="flint/flint_FCCSW.txt", text="FCC Core Software (w/ flint++)"))
        fobj.write(link_template.format(href="flint/flint_Gaussino.txt", text="Gaussino (w/ flint++)"))
        fobj.write("</ul>")
        fobj.write("<b>Runtime performance:</b>")
        fobj.write("<ul>")
        fobj.write(link_template.format(href="cgi-bin/igprof-navigator/fccedm-write", text="FCC EDM example (igprof)"))
        fobj.write("</ul></div><div class='clearfix'>&nbsp;</div><hr><footer><small>last generated on {date} by {user}</small></footer></div>".format(
            date=time.strftime("%d %b", time.localtime()),
            user=os.getlogin()
            )
        )
        fobj.write(footer)


if __name__ == "__main__":
    main()
