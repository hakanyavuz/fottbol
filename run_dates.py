import re

with open('tff.html', 'rb') as f:
    txt = f.read().decode('windows-1254', 'ignore')

blocks = txt.split('class="row haftaninMaclariMaclar"')
print(f"Toplam blok: {len(blocks)}")
with open('tff_superlig_dates.txt', 'w', encoding='utf-8') as out:
    for i, b in enumerate(blocks[1:15]):
        # Tarih ve gün yakala
        m_tarih = re.search(r'([0-9]{2}\.[0-9]{2}\.[0-9]{4})', b)
        m_saat = re.search(r'([0-9]{2}:[0-9]{2})', b)
        ev = re.search(r'hypEvSahibi"[^>]*>([^<]+)', b)
        dep = re.search(r'hypMisafir"[^>]*>([^<]+)', b)
        sk = re.search(r'_mac"[^>]*>([^<]+)', b)
        hk = re.search(r'_hakem"[^>]*>([^<]+)', b)
        stad = re.search(r'hypsaha"[^>]*>([^<]+)', b)
        
        t_val = m_tarih.group(1) if m_tarih else 'Tarih Yok'
        s_val = m_saat.group(1) if m_saat else ''
        ev_val = ev.group(1).strip() if ev else ''
        dep_val = dep.group(1).strip() if dep else ''
        sk_val = sk.group(1).strip() if sk else 'Oynanmadi'
        hk_val = hk.group(1).strip() if hk else ''
        stad_val = stad.group(1).strip() if stad else ''
        
        out.write(f"{t_val} {s_val} | {ev_val} vs {dep_val} | Skor: {sk_val} | Hakem: {hk_val} | {stad_val}\n")
