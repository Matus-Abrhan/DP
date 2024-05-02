import json
import sys
import yaml  # pip3 install yaml
import os
import re


class SpecTransformer:

    STRING_CONST = "string"
    INT_CONST = "int"
    unknown_type = False
    spec_path = ""
    GUARD_FILENAME = "guard"
    ACTION_FILENAME = ".ml"

    def transform(self, spec, onto_types):
        spec_ = spec
        splitter = ""
        for type, attribute in onto_types.items():
            pattern = re.compile(
                r"([a-zA-Z]+[a-zA-Z0-9_]*)\(\?([a-zA-Z]+[a-zA-Z0-9_]*)\:"+type+"\)")
            for (event_label, variable) in re.findall(pattern, spec_):

                event_params = ''
                for var_attribute, var_type in attribute.items():
                    if self.INT_CONST in var_type:
                        event_params = event_params + '?' + var_attribute + ':' + self.INT_CONST + ','
                    else:
                        event_params = event_params + '?' + var_attribute + ':' + self.STRING_CONST + ','

                event_params = event_params[:-1]
                target = event_label + '(' + event_params + ')'
                spec_ = spec_.replace(
                    event_label + '(?' + variable + ':' + type + ')', target)
                spec_ = spec_.replace(variable+".", "")

                files = [os.path.join(dp, f) for dp, dn, fns in os.walk(
                    self.spec_path) for f in fns]

                for f in files:
                    if self.GUARD_FILENAME in f.lower():
                        guard_f = open(f, "r")
                        content = str(guard_f.read()).replace(
                            str(variable)+".", "")
                        guard_f.close()
                        guard_f = open(f, "w+")
                        guard_f.write(str(content))
                        guard_f.close()
                    if self.ACTION_FILENAME in f.lower():
                        action_f = open(f, "r")
                        content = str(action_f.read()).replace(
                            str(variable)+".", "")
                        action_f.close()
                        action_f = open(f, "w+")
                        action_f.write(str(content))
                        action_f.close()

                if not (type in splitter):
                    splitter = splitter + type + '@'

                self.unknown_type = True

        if self.unknown_type:
            splitter = splitter[:-1]
            return splitter+"&"+spec_
        else:
            return "Packet&"+spec_


if __name__ == "__main__":

    if len(sys.argv) < 2:
        print("python spectransform.py spec_location")
    else:
        ymlfile = "config.yaml"
        cfg = yaml.load(open(ymlfile, "r"), Loader=yaml.FullLoader)
        PATH = cfg['CONFIGS']['ONTOLOGY_CONFIGS']['FEED_CHANNELS']['channel1']['target']
        if PATH:
            st = SpecTransformer()
            st.spec_path = os.path.abspath(
                os.path.join(sys.argv[1], os.pardir))
            spec_raw = re.sub('[\n\t ]', '', open(sys.argv[1], "r").read())
            try:
                str = st.transform(spec_raw, json.load(open(PATH, "r")))
                print(str)
            except UnicodeDecodeError:
                print(spec_raw)
