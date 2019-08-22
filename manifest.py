from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import sys
reload(sys)
sys.setdefaultencoding("utf-8")

import os
import codecs
import soundfile
import json
import argparse

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument(
    "--target_dir",
    default="/mnt/rds/redhen/gallina/Singularity/Zhaoqing/example/split",
    type=str,
    help="Directory to save the dataset. (default: %(default)s")
parser.add_argument(
    "--manifest_path",
    default="manifest.ex",
    type=str,
    help="The path of the output manifest"
)
args = parser.parse_args()


def create_manifest(data_dir,manifest_path):
    print("Creating manifest %s" % manifest_path)
    json_lines = []
    for subfolder,_,filelist in sorted(os.walk(data_dir)):
	for fname in sorted(filelist):
		audio_path = os.path.join(subfolder,fname)
		audio_id = fname[:-3]
		audio_data, samplerate = soundfile.read(audio_path)
                duration = float(len(audio_data) / samplerate)
                text = ''
                json_lines.append(
                    json.dumps(
                        {
                            'audio_filepath': audio_path,
                            'duration': duration,
                            'text': text
                        },
                        ensure_ascii=False))
        with codecs.open(manifest_path, 'w', 'utf-8') as fout:
            for line in json_lines:
                fout.write(line + '\n')

def main():
    if args.target_dir.startswith('~'):
        args.target_dir = os.path.expanduser(args.target_dir)
    create_manifest(args.target_dir,args.manifest_path)

main()
