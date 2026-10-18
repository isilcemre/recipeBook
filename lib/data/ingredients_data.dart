/// Kategorilere göre malzeme listesi.
/// Sıra, "Elde Ne Var" ekranındaki sekme sırasıyla aynıdır.
const Map<String, List<String>> kIngredientCategories = {
  'Temel': [
    'Tuz', 'Şeker', 'Un', 'Tereyağı', 'Zeytinyağı', 'Ayçiçek yağı',
    'Sıvı yağ', 'Sirke', 'Limon suyu', 'Limon', 'Su', 'Soğuk su',
  ],
  'Sebzeler': [
    'Soğan', 'Sarımsak', 'Domates', 'Biber', 'Sivri biber', 'Dolmalık biber',
    'Kırmızı biber', 'Yeşil biber', 'Kapya biber', 'Acı biber', 'Havuç',
    'Patates', 'Patlıcan', 'Kabak', 'Ispanak', 'Lahana', 'Brokoli',
    'Karnabahar', 'Bezelye', 'Mısır', 'Bamya', 'Enginar', 'Kereviz', 'Pırasa',
    'Turp', 'Pancar', 'Semizotu', 'Salatalık', 'Marul', 'Roka', 'Taze fasulye',
    'Barbunya', 'Kuşkonmaz', 'Mantar', 'Zeytin', 'Yeşil zeytin',
    'Siyah zeytin', 'Kapari',
  ],
  'Yeşillik & Otlar': [
    'Maydanoz', 'Dereotu', 'Nane', 'Taze nane', 'Taze soğan', 'Fesleğen',
    'Kişniş', 'Reyhan', 'Taze kekik',
  ],
  'Et & Protein': [
    'Tavuk', 'Tavuk göğsü', 'Tavuk but', 'Kıyma', 'Dana eti', 'Dana kıyma',
    'Kuzu eti', 'Kuzu kıyma', 'Kuzu pirzola', 'Biftek', 'Sucuk', 'Pastırma',
    'Sosis', 'Balık', 'Levrek', 'Çipura', 'Hamsi', 'Somon', 'Ton balığı',
    'Karides', 'Midye',
  ],
  'Yumurta & Süt Ürünleri': [
    'Yumurta', 'Süt', 'Yoğurt', 'Kaşar', 'Kaşar peyniri', 'Beyaz peynir',
    'Lor peyniri', 'Tulum peyniri', 'Çökelek', 'Krema', 'Sıvı krema', 'Labne',
    'Ayran',
  ],
  'Bakliyat & Tahıllar': [
    'Pirinç', 'Bulgur', 'Makarna', 'Şehriye', 'Kırmızı mercimek',
    'Yeşil mercimek', 'Nohut', 'Kuru fasulye', 'Börülce', 'Ekmek', 'Ekmek içi',
    'Bayat ekmek', 'Yufka', 'Tost ekmeği', 'Mısır unu', 'Nişasta', 'İrmik',
    'Yulaf', 'Galeta unu',
  ],
  'Baharatlar': [
    'Karabiber', 'Kimyon', 'Pul biber', 'Kırmızı pul biber', 'Kekik',
    'Biberiye', 'Zerdeçal', 'Tarçın', 'Defne yaprağı', 'Sumak', 'İsot', 'Köri',
    'Zencefil', 'Muskat', 'Kişniş tohumu', 'Rezene', 'Safran', 'Vanilya',
    'Karanfil', 'Yenibahar', 'Çörek otu',
  ],
  'Kuruyemiş & Kuru Meyve': [
    'Ceviz', 'Fındık', 'Badem', 'Fıstık', 'Antep fıstığı', 'Çam fıstığı',
    'Susam', 'Kuru üzüm', 'Kayısı kurusu', 'İncir kurusu', 'Hurma',
  ],
  'Sos & Salçalar': [
    'Domates salçası', 'Biber salçası', 'Soya sosu', 'Nar ekşisi', 'Ketçap',
    'Mayonez', 'Hardal', 'Tahin',
  ],
  'Tatlı & Fırın': [
    'Çikolata', 'Bitter çikolata', 'Sütlü çikolata', 'Kakao', 'Kabartma tozu',
    'Karbonat', 'Maya', 'Kuru maya', 'Pudra şekeri', 'Esmer şeker', 'Bal',
    'Pekmez', 'Reçel', 'Hindistancevizi',
  ],
  'Meyveler': [
    'Elma', 'Armut', 'Portakal', 'Mandalina', 'Muz', 'Çilek', 'Vişne', 'Kiraz',
    'Şeftali', 'Kayısı', 'Erik', 'Nar', 'Üzüm', 'Karpuz', 'Kavun', 'İncir',
    'Avokado',
  ],
  'İçecek & Diğer': [
    'Çay', 'Türk kahvesi', 'Salep',
  ],
};

/// Tüm malzemelerin düz listesi (tarif formu bunu kullanmaya devam eder).
final List<String> kAllIngredients =
    kIngredientCategories.values.expand((list) => list).toList();