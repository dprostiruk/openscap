#!/usr/bin/env python3
import xml.etree.ElementTree as ET
import json, csv, os, sys

SSG_CONTENT = os.getenv("SSG_CONTENT","/opt/ssg/scap-security-guide-0.1.78/ssg-ubuntu2204-ds.xml")
RES_XML = "/tmp/results.xml"

if not os.path.exists(RES_XML):
    print("No results.xml at /tmp/results.xml")
    sys.exit(0)

# парсим XCCDF content чтобы получить правила
# для простоты возьмём Rule элементы из DS (может потребоваться namespace handling)
ns = {'xccdf': 'http://checklists.nist.gov/xccdf/1.2'}
tree = ET.parse(SSG_CONTENT)
root = tree.getroot()
rules = {}
for r in root.findall('.//{http://checklists.nist.gov/xccdf/1.2}Rule'):
    rid = r.get('id')
    sev = r.get('severity')
    # get ident CCI if exists
    cci = ""
    ident = r.find("{http://checklists.nist.gov/xccdf/1.2}ident[@system='http://cyber.mil/cci']")
    if ident is not None and ident.text:
        cci = ident.text
    check = ""
    ch = r.find("{http://checklists.nist.gov/xccdf/1.2}check")
    if ch is not None:
        cc = ch.find("{http://checklists.nist.gov/xccdf/1.2}check-content")
        if cc is not None and cc.text:
            check = cc.text.strip()
    fix = ""
    fx = r.find("{http://checklists.nist.gov/xccdf/1.2}fix")
    if fx is not None and fx.text:
        fix = fx.text.strip()
    rules[rid] = {"severity": sev, "cci": cci, "check": check, "fix": fix}

# парсим results.xml
res_tree = ET.parse(RES_XML)
res_root = res_tree.getroot()
res_namespace = "{http://checklists.nist.gov/xccdf/1.2}"
out = []
for rr in res_root.findall('.//{http://checklists.nist.gov/xccdf/1.2}rule-result'):
    rid = rr.get('idref')
    result_el = rr.find(f'{res_namespace}result')
    result = result_el.text if result_el is not None else 'unknown'
    meta = rules.get(rid, {})
    out.append({
        "rule_id": rid,
        "severity": meta.get("severity",""),
        "cci": meta.get("cci",""),
        "check": meta.get("check",""),
        "fix": meta.get("fix",""),
        "result": result
    })

# write files
with open("/tmp/stig_metrics.json","w") as f:
    json.dump(out,f,indent=2)

with open("/tmp/stig_metrics.csv","w",newline='') as f:
    w = csv.writer(f)
    w.writerow(["rule_id","severity","cci","check","fix","result"])
    for row in out:
        w.writerow([row["rule_id"],row["severity"],row["cci"],row["check"],row["fix"],row["result"]])

print("Wrote /tmp/stig_metrics.json and /tmp/stig_metrics.csv")
