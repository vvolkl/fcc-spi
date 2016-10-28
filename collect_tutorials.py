import urllib2 as urllib
import json
import os
import base64
import re

# caching (currently not re-used)
repo_contents = {}

class MarkDownFile():
    """ helper class to save the pair of url and path of an md file"""
    def __init__(self, url, path):
        self.url = url
        self.path = path


def get_repo_contents(repo, commit):
    """ get the tree of the repository contents """
    url = 'https://api.github.com/repos/{repo}/git/trees/{sha}?recursive=1'.format(repo=repo, sha=commit)
    fobj = urllib.urlopen(url)
    repo_contents[repo+commit] = json.loads(fobj.read())


def find_markdown(repo, commit):
    """ return a list of markdown files in the repo """
    if repo not in repo_contents.keys():
        get_repo_contents(repo, commit)
    contents = repo_contents[repo+commit]
    return [MarkDownFile(elt["url"], elt["path"]) for elt in contents["tree"] if elt["path"].endswith(".md")]


def get_commit_sha(repo, tag):
    """ get the commit-ish sha of a tag """
    if tag == "master":
        return "master"
    else:
        url = 'https://api.github.com/repos/{repo}/releases/tags/{tag}'
        fobj = urllib.urlopen(url.format(repo=repo, tag=tag))
        return json.loads(fobj.read())["target_commitish"]


def get_encoded_content(url):
    fobj = urllib.urlopen(url)
    return json.loads(fobj.read())["content"]

def convert_markdown_links(match):
    """ for relative links: convert *.md to *.html (for the links to work both on github and in jekyll) """
    label = match.group(1)
    url = match.group(2)
    ret_string = "[{label}]({url})"
    # naive capture of non-local links (e.g. directly to github):
    if not url.startswith("http"):
        url = url.replace('.md', '.html')
    return ret_string.format(label=label, url=url)


def copy_tutorials(user_name, repo_name, tag):
    """ get all .md files from the repository and save them locally """
    base_path = os.path.join("docpage", "tutorials", repo_name)
    front_matter = "---\nlayout: site\n---\n"
    full_repo_name = "{user}/{repo}".format(user=user_name, repo=repo_name)
    tag = "master"

    tag_sha = get_commit_sha(full_repo_name, tag)
    md_files = find_markdown(full_repo_name, tag_sha)
    for md in md_files:
        if "doc/README.md" == md.path:
            continue
        path_elts = md.path.split("/")
        package, tutorial = path_elts[0], path_elts[-1]
        if package == tutorial:
            package = ""
        path = os.path.join(base_path, package)
        if not os.path.isdir(path):
            print "creating directory:", path
            os.makedirs(path)

        encoded_content = get_encoded_content(md.url)
        fname = os.path.join(path, tutorial)
        with open(fname, 'w') as fobj:
            print "writing", fname
            fobj.write(front_matter)
            content = base64.b64decode(encoded_content)
            content = re.sub("\[(.+)\]\(([^\)]*)\)", convert_markdown_links, content)
            fobj.write(content)


def index_list(repo, headlines):
    """ go through directories and create a list of links """
    sub_strings = []
    base_path = os.path.join("docpage", "tutorials")
    repo_strings = []
    for root, dirs, files in os.walk(os.path.join(base_path, repo)):
        rel_path = os.path.relpath(root, base_path)
        depth = len(rel_path[1:].split(os.sep)) - 1
        # if we have a new package add a "headline":
        if depth > 0:
            n = rel_path.replace(repo, "").replace(os.sep, " ")
            if n == " doc":
                n = "General documentation of " + repo
            repo_strings.append("\n#### {name}\n".format(name=n))
        for filename in files:
            link_name = filename.lstrip("Fcc").replace(".md", "")
            if link_name == "README" and depth != 0:
                link_name = "General information"
            elif link_name == "README":
                link_name = "Quick start guide"
            # transform camel-case to individual words
            link_name = re.sub("([a-z])([A-Z])", "\g<1> \g<2>", link_name)
            link_name = link_name.replace("_", " ")
            repo_strings.append("- [{label}]({ref})".format(label=link_name, ref=os.path.join(rel_path, filename.replace(".md", ".html"))))

    if len(repo_strings) > 0:
        sub_strings.append("\n### {headline}\n".format(headline=headlines[repo]))
        sub_strings += repo_strings

    return sub_strings

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

    with open(os.path.join(base_path, "index.md"), "w") as fobj:
        fobj.write(head.format(tutorial_list="\n".join(index+sub_strings)))


def main():
    # translation repo-name -> headline
    headlines = {"FCCSW": "FCCSW\nthe full framework (event generation, simulation and reconstruction)\n",
                 "heppy": "heppy\nthe python analysis framework and PAPAS simulation\n",
                 "fcc-physics": "fcc-physics\nlightweight C++ analysis\n",
                 "fcc-edm": "fcc-edm\nthe event data model\n",
                 "podio": "podio\nlibrary to create and describe the event data model\n",
                 "fcc-tutorials": "General tutorials\nStart here\n"
                }
    # the order defines also order in index (fcc-tutorial is treated differently)
    repo_names = ["fcc-tutorials", "FCCSW", "fcc-physics", "fcc-edm", "podio"]
    for repo in repo_names:
        copy_tutorials("jlingema", repo, "master")
    # get list of links to all .md files in the repo (all repos except fcc-tutorials)
    index_fragments = []
    for repo in repo_names[1:]:
        index_fragments += index_list(repo, headlines)
    # finaly: create the index
    create_index(index_fragments)



if __name__ == "__main__":
    main()
