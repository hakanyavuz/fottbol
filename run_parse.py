import re

with open('tff.html', 'rb') as f:
    txt = f.read().decode('windows-1254', 'ignore')

blocks = txt.split('class="row haftaninMaclariMaclar"')
with open('tff_superlig.txt', 'w', encoding='utf-8') as out:
    for b in blocks[1:]:
        t = re.search(r'lblTarih"[^>]*>([^<]+)', b)
        st = re.search(r'lblSaat"[^>]*>([^<]+)', b)
        ev = re.search(r'hypEvSahibi"[^>]*>([^<]+)', b)
        dep = re.search(r'hypMisafir"[^>]*>([^<]+)', b)
        sk = re.search(r'_mac"[^>]*>([^<]+)', b)
        hk = re.search(r'_hakem"[^>]*>([^<]+)', b)
        stad = re.search(r'hypsaha"[^>]*>([^<]+)', b)
        if ev and dep:
            t_str = t.group(1).strip() if t else ''
            st_str = st.group(1).strip() if st else ''
            ev_str = ev.group(1).strip()
            dep_str = dep.group(1).strip()
            sk_str = sk.group(1).strip() if sk else 'Oynanmadi'
            hk_str = hk.group(1).strip() if hk else ''
            stad_str = stad.group(1).strip() if stad else ''
            out.write(f'{t_str} {st_str} | {ev_str} - {dep_str} | Skor: {sk_str} | Hakem: {hk_str} | {stad_str}\n')
print("Complete")
