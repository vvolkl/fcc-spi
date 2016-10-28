import mistune
import subprocess
import argparse
import os
import sys


class ExecutableExtractor(mistune.Renderer):
    def __init__(self):
        super(ExecutableExtractor, self).__init__()
        self.fragments = []

    def block_code(self, code, lang):
        if not lang is None and lang == "bash":
            self.fragments.append(code)
        return ''

    @staticmethod
    def update_env(key_value):
        # FIXME: hack to exit for function definitions
        if "(" or ")" in key_value:
            return
        key, _, value = key_value.partition("=")
        if key == "_": return
        if key in os.environ.keys() and os.environ[key] != value:
            print 'updating environment: ', key, '=', value
            os.environ[key] = value

    def execute_fragments(self):
        for code in self.fragments:
            code = code.replace(";", "\n").replace("&&", "\n")
            for l_frag in code.splitlines():
                frag = l_frag.strip()
                if frag.startswith('cd'):
                    _, directory = frag.split()
                    os.chdir(directory)
                    continue
                if frag.startswith('export'):
                    self.update_env(frag)
                    continue
                if frag.startswith('source'):
                    command = ['bash', '-c', 'source ' + frag.split()[1] + ' && env']
                    try:
                        environment = subprocess.check_output(command)
                        for keyvalpair in environment.splitlines():
                            self.update_env(keyvalpair)
                        continue
                    except OSError as e:
                        print "ERROR while executing: ", frag
                        return 1
                try:
                    subprocess.call(frag.split())
                except OSError as e:
                    print "ERROR: can't execute: ", frag
                    return 1
        return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser("FCC release creator", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('file', type=str, help='the tutorial to test')
    parser.add_argument('--output', '-o', type=str, help='output the environment (for consecutive tutorials)')
    args = parser.parse_args()
    exe_extractor = ExecutableExtractor()
    markdown = mistune.Markdown(renderer=exe_extractor)
    with open(args.file, 'r') as fobj:
        markdown(fobj.read())
    sys.exit(exe_extractor.execute_fragments())
