import urllib2 as urllib
import json
import os
import base64
import re
import pickle
import argparse

# caching (currently not re-used)
repo_contents = {}

panel_template = """
<div class='col-md-4' style='padding:10px;'>
<div class='panel panel-default'>
    <div class='panel-heading'><h3 class='panel-title'>{title}</h3></div>
    <div class='panel-body'>{content}</div>
</div>
</div>
"""

class GithubFile():
    """ helper class to save the pair of url and path of an md file"""
    def __init__(self, url, path):
        self.url = url
        self.path = path


def get_repo_contents(repo, commit):
    """ get the tree of the repository contents """
    global repo_contents
    url = 'https://api.github.com/repos/{repo}/git/trees/{sha}?recursive=1'.format(repo=repo, sha=commit)
    print 'Updating repo trees, contacting:', url
    fobj = urllib.urlopen(url)
    repo_contents[repo+commit] = json.loads(fobj.read())


def find_files_of_type(repo, commit, suffix=".md"):
    """ return a list of markdown files in the repo """
    if repo+commit not in repo_contents.keys():
        get_repo_contents(repo, commit)
    contents = repo_contents[repo+commit]
    return [GithubFile(elt["url"], elt["path"]) for elt in contents["tree"] if elt["path"].endswith(suffix)]


def get_commit_sha(repo, tag):
    """ get the commit-ish sha of a tag """
    if tag == "master":
        return "master"
    else:
        url = 'https://api.github.com/repos/{repo}/releases/tags/{tag}'
        fobj = urllib.urlopen(url.format(repo=repo, tag=tag))
        return json.loads(fobj.read())["target_commitish"]


def get_content(markdown, repo_name, local_copy, save_to):
    """ get file content from github """
    if local_copy != "":
        fname = os.path.join(local_copy, repo_name, markdown.path)
        with open(fname, 'r') as fobj:
            return fobj.read()
    fname = os.path.join(save_to, repo_name, markdown.path)
    fobj = urllib.urlopen(markdown.url)
    objdesc = json.loads(fobj.read())
    content_str = base64.b64decode(objdesc["content"])
    if save_to != "":
        directory = os.path.dirname(fname)
        if not os.path.isdir(directory):
            os.makedirs(directory)
        with open(fname, 'w') as save_fobj:
            save_fobj.write(content_str)
    return content_str

def convert_markdown_links(match):
    """ for relative links: convert *.md to *.html (for the links to work both on github and in jekyll) """
    label = match.group(1)
    url = match.group(2)
    ret_string = "[{label}]({url})"
    # naive capture of non-local links (e.g. directly to github):
    if not url.startswith("http"):
        url = url.replace('.md', '.html')
    elif url.startswith("https://github.com/HEP-FCC/") and url.endswith(".md"):
        url = url.replace('.md', '.html')
        url = url.replace('https://github.com/HEP-FCC/', '../')
        url = url.replace('/tree/master/', '/')
        url = url.replace('/blob/master/', '/')
    return ret_string.format(label=label, url=url)


def convert_fences(match):
    """ converts fences from doxy+github flavour to kramdown flavor """
    syntax = match.group(2)[1:-1]
    lookup = {".cpp":"cpp", ".xml":"xml", ".py":"python", ".sh":"bash", ".cmake":"cmake"}
    return match.group(1) + lookup[syntax]


def copy_tutorials(user_name, repo_name, tag, local_copy="", save_to=""):
    """ get all .md and .png files from the repository and save them locally """
    base_path = os.path.join("docpage", "tutorials", repo_name)
    front_matter = "---\nlayout: site\n---\n"
    full_repo_name = "{user}/{repo}".format(user=user_name, repo=repo_name)
    tag = "master"

    tag_sha = get_commit_sha(full_repo_name, tag)
    all_files = find_files_of_type(full_repo_name, tag_sha, ".md")
    all_files += find_files_of_type(full_repo_name, tag_sha, ".png")
    for fdesc in all_files:
        if "doc/README.md" == fdesc.path:
            continue
        path, fname = os.path.split(fdesc.path)
        path = os.path.join(base_path, path)
        if not os.path.isdir(path):
            print "creating directory:", path
            os.makedirs(path)

        content = get_content(fdesc, repo_name, local_copy, save_to)
        fname = os.path.join(path, fname)
        with open(fname, 'w') as fobj:
            print "writing", fname
            if fname.endswith(".md"):
                fobj.write(front_matter)
                content = re.sub("\[(.+)\]\(([^\)]*)\)", convert_markdown_links, content)
                content = re.sub("([~*])({\.[a-zA-Z0-9]+})", convert_fences, content)
            fobj.write(content)

def index_list(repo, headlines):
    """ go through directories and create a list of links """
    sub_strings = []
    base_path = os.path.join("docpage", "tutorials")
    repo_strings = []
    for root, dirs, files in os.walk(os.path.join(base_path, repo)):
        if len(files) == 0: continue
        rel_path = os.path.relpath(root, base_path)
        depth = len(rel_path[1:].split(os.sep)) - 1
        # if we have a new package add a "headline":
        if depth > 0:
            n = rel_path.replace(repo, "").replace(os.sep, " ").replace("doc", "").strip()
            if n == "":
                n = "General documentation"
            repo_strings.append("\n**{name}**\n\n".format(name=n.strip()))
        for filename in files:
            link_name = filename.replace(".md", "")
            if link_name == "README" and depth != 0:
                link_name = "General information"
            elif link_name == "README":
                link_name = "Quick start guide"
            # otherwise transform camel-case and snake case to individual words
            link_name = re.sub("([a-z])([A-Z])", "\g<1> \g<2>", link_name)
            link_name = link_name.replace("_", " ")
            repo_strings.append("- [{label}]({ref})".format(label=link_name, ref=os.path.join(rel_path, filename.replace(".md", ".html"))))

    panel = ""
    if len(repo_strings) > 0:
        cnt = "{{{{ \"{content}\" | markdownify }}}}".format(content="\n".join(repo_strings))
        panel = panel_template.format(title=headlines[repo], content=cnt)

    return panel

def convert_index_link(match):
    """ converts indexes from fcc-tutorial README """
    ref = "./fcc-tutorials/" + match.group(2)
    new_link = "[{label}]({link})".format(label=match.group(1), link=ref)
    return new_link


def create_index(sub_strings):
    """
    loads template from ./templates/index.md.in and adds:
        - front-matter
        - treated README.md of fcc-tutorials
        - list of links
    """
    base_path = os.path.join("docpage", "tutorials")
    front_matter = "---\nlayout: site\n---\n"
    with open("./templates/index.md.in") as fobj:
        head = front_matter +  fobj.read()
    # assume that tutorials has a README with an index
    index = []
    with open(os.path.join(base_path, "fcc-tutorials", "README.md")) as fobj:
        # convert links
        idx_string = fobj.read()
        idx_string = idx_string.replace(front_matter, "")
        idx_string = re.sub("\[(.+)\]\(([^\)]*)\)", convert_index_link, idx_string)
        index = [idx_string]

    index.append("### Further Reading")
    with open(os.path.join(base_path, "index.md"), "w") as fobj:
        fobj.write(head.format(tutorial_list="\n".join(index)+sub_strings))


def main():
    global repo_contents
    # These options are mainly meant when developing / changing this script or testing local changes to the repos.
    # When you have to run the script several times in a short timespan you may run into the API connection limitation,
    # For that, it may also be good to use a local version
    parser = argparse.ArgumentParser("FCC tutorial collector", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--loadfiles', type=str, default='', help='path to local copy of the tutorials')
    parser.add_argument('--savefiles', type=str, default='', help='path where to save local copy of the tutorials')
    parser.add_argument('--savetree', type=str, default='', help='pickle repository tree to this location')
    parser.add_argument('--loadtree', type=str, default='', help='load pickled repository trees')
    args = parser.parse_args()

    if args.loadtree != '':
        with open(args.loadtree, 'r') as fobj:
            repo_contents = pickle.load(fobj)

    # translation repo-name -> headline
    headlines = {"FCCSW": "FCCSW - the full framework\n",
                 "heppy": "heppy - python analysis and PAPAS simulation\n",
                 "fcc-physics": "fcc-physics - C++ analysis light\n",
                 "fcc-edm": "fcc-edm - the event data model\n",
                 "podio": "podio - EDM description library \n"
                }
    # the order defines also order in index (fcc-tutorial is treated differently)
    repo_names = ["fcc-tutorials", "FCCSW", "fcc-physics", "heppy", "fcc-edm", "podio"]
    for repo in repo_names:
        copy_tutorials("HEP-FCC", repo, "master", args.loadfiles, args.savefiles)
    # get list of links to all .md files in the repo (all repos except fcc-tutorials)
    index_fragments = ""
    for repo in repo_names[1:]:
        index_fragments += index_list(repo, headlines)
    # finaly: create the index
    create_index(index_fragments)

    if args.savetree != '':
        with open(args.savetree, 'w') as fobj:
            pickle.dump(repo_contents, fobj)


if __name__ == "__main__":
    main()
