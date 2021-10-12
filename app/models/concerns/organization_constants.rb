# frozen_string_literal: true

module OrganizationConstants
  SCOPE = %w[International National Regional].freeze

  NTEE_CODE = %w[A00 A90 A26 A91 A02 Q21 A25 A24 A23 A40 A41
                 A48 A47 A44 A46 A45 A42 A43 A49 A60 A62 A63
                 A64 A65 A67 A66 A68 A6D A6C A6A A69 A6B A6F
                 A6G A6E A50 A51 A52 A53 A54 A55 A56 A5A A57
                 A58 A70 A71 A72 A74 A75 A76 A77 A80 A84 A83
                 A82 A85 B00 B13 B02 B20 B24 B23 B25 B26 B29
                 B27 B28 B22 B30 B32 B31 B40 B41 B42 B43 B50
                 B51 B53 B54 B59 B56 B55 B60 B61 B64 B63 B80
                 B84 B83 B90 B96 B95 B91 Q22 B93 B97 B94 B92
                 B21 C00 C13 C28 C30 C21 C26 C27 C25 C24 C32
                 C22 C34 C35 D30 D51 D33 D32 D31 D34 D50 C38
                 C41 C36 D00 D20 D21 D60 D40 C60 T00 T06 T20
                 S50 T40 T80 E00 E13 E80 E85 E83 E02 E81 E31
                 E86 R27 E87 E20 E38 E21 E22 E26 E24 E30 E32
                 E34 E35 E90 E92 P74 E89 E40 E42 E43 E41 E46
                 E33 P35 E47 E50 E52 E51 E53 E37 E60 E61 E63
                 E65 E66 F30 F31 F32 F33 F34 F20 F53 F52 F21
                 F22 F40 F41 F42 F60 F61 E70 E72 E78 E74 E73
                 E71 E77 K40 E76 E79 E7B E7A G90 G92 G9A G94
                 G9F G9C G95 G96 G9E G9D G97 G98 G9G G9H G9B
                 G00 G50 G51 G52 G48 G83 G58 G84 G23 G54 G53
                 G55 G57 G70 G47 G42 G41 G85 G43 G81 G44 F70
                 G82 F72 G86 F71 G45 G61 G46 G20 G24 G25 G21
                 G30 G32 G31 G33 U00 U30 U31 U33 U35 U36 U21
                 U40 U43 U41 U42 U32 U50 U52 U51 U53 U34 V00
                 V21 V21 V22 V23 V24 V25 V26 V30 V3A V33 V31
                 V32 V36 V35 V37 V39 V38 V34 V40 A36 A3H A37
                 A38 A39 B70 B73 B77 B71 B72 A3D A3E A3G A3F
                 A30 A3A A31 A33 A34 A32 A3C A35 W54 W53 A3B
                 W50 W52 I20 I23 I22 I24 I60 I70 I72 I71 I73
                 I50 I51 I80 I82 I81 I84 I83 I30 I44 I41 I40
                 I43 I31 M20 M21 M22 M23 M24 M40 M41 M42 M43
                 W90 W91 W00 W06 W70 S25 W24 W23 W26 W25 R40
                 W20 W22 W21 Q43 I25 E75 W80 W82 W81 K00 K20
                 K21 K28 K18 K22 K25 K26 K23 K24 S00 S30 S31
                 W40 S32 J21 J22 J23 J40 Y30 S20 C50 C42 C43
                 S21 S22 S80 L20 L25 L21 L51 L52 W60 S45 W61
                 Y20 P51 S40 S41 S43 S42 S47 S33 X00 X80 X50
                 X20 X21 X22 X23 X24 X60 X70 X40 X30 X90 X91
                 A78 N00 N30 N20 N32 N52 N50 N60 N63 N62 N69
                 N65 N6A N61 N66 N64 N68 N67 N6B N71 N72 N40
                 N41 R00 R62 R67 R6D Q72 R63 R66 R65 Q71 R61
                 R6E R6G R64 R6B R6C R6A R68 R69 R20 R21 R22
                 R23 R24 R25 R26 R28 R30 P00 P02 P14 P60 P61
                 P62 P29 P58 K30 K31 K32 K34 P40 P71 P45 P34
                 P31 P33 P37 P32 P46 P48 P44 P41 P42 O00 O23
                 O40 O30 O32 O50 O52 O53 O54 O51 O55 P50 Y50
                 P52 P54 P53 P59 P57 L00 P70 P43 L24 P73 P72
                 P75 L22 E91 L80 L83 L81 L82 L41 L40 J33 J30
                 P80 P82 P85 P89 P81 P83 Q00 Q50 Q20 Q30 Q51
                 Q23 Q42 Q40 Q41 Q44 Z00].freeze

    CATEGORIES_AND_SUBCATEGORIES = {
                "Agriculture, fishing and forestry"=>"Agriculture", 
                "Agriculture, fishing and forestry"=>"Fishing and aquaculture", 
                "Agriculture, fishing and forestry"=>"Food security", 
                "Agriculture, fishing and forestry"=>"Forestry", 
                "Arts and culture"=>"Arts services", 
                "Arts and culture"=>"Cultural awareness", 
                "Arts and culture"=>"Folk arts", 
                "Arts and culture"=>"Historical activities", 
                "Arts and culture"=>"Humanities", 
                "Arts and culture"=>"Museums", 
                "Arts and culture"=>"Performing arts",
                "Arts and culture"=>"Public arts",
                "Arts and culture"=>"Visual arts", 
                "Community and economic development"=>"Business and industry", 
                "Community and economic development"=>"Community improvement", 
                "Community and economic development"=>"Economic development", 
                "Community and economic development"=>"Financial services", 
                "Community and economic development"=>"Housing development", 
                "Community and economic development"=>"Sustainable development", 
                "Education"=>"Adult education", "Education"=>"Early childhood education", 
                "Education"=>"Education services", "Education"=>"Educational management", 
                "Education"=>"Elementary and secondary education", 
                "Education"=>"Equal opportunity in education", 
                "Education"=>"Graduate and professional education", 
                "Education"=>"Higher education", 
                "Education"=>"Student services", 
                "Education"=>"Vocational education", 
                "Environment"=>"Biodiversity", 
                "Environment"=>"Climate change", 
                "Environment"=>"Domesticated animals", 
                "Environment"=>"Environmental education", 
                "Environment"=>"Environmental justice", 
                "Environment"=>"Natural resources", 
                "Health"=>"Diseases and conditions", 
                "Health"=>"Health care access", 
                "Health"=>"Health care administration and financing", 
                "Health"=>"Health care quality", 
                "Health"=>"Holistic medicine", 
                "Health"=>"In-patient medical care", 
                "Health"=>"Medical specialties", 
                "Health"=>"Medical support services", 
                "Health"=>"Mental health care", 
                "Health"=>"Nursing care", 
                "Health"=>"Out-patient medical care", 
                "Health"=>"Public health", 
                "Health"=>"Rehabilitation", 
                "Health"=>"Reproductive health care", 
                "Health"=>"Traditional medicine and healing", 
                "Human rights"=>"Antidiscrimination", 
                "Human rights"=>"Diversity and intergroup relations", 
                "Human rights"=>"Individual liberties", 
                "Human rights"=>"Justice rights", 
                "Human rights"=>"Social rights", 
                "Human services"=>"Basic and emergency aid",
                "Human services"=>"Family services", 
                "Human services"=>"Human services information", 
                "Human services"=>"Human services management", 
                "Human services"=>"Job services", 
                "Human services"=>"Personal services", 
                "Human services"=>"Shelter and residential care", 
                "Human services"=>"Special population support", 
                "Human services"=>"Youth development", 
                "Information and communications"=>"Communication media", 
                "Information and communications"=>"Information and communications technology", 
                "Information and communications"=>"Libraries", 
                "Information and communications"=>"Media access and policy", 
                "Information and communications"=>"News and public information", 
                "International relations"=>"Foreign policy", 
                "International relations"=>"Goodwill promotion", 
                "International relations"=>"International development", 
                "International relations"=>"International economics and trade", 
                "International relations"=>"International exchange", 
                "International relations"=>"International peace and security", 
                "International relations"=>"Multilateral cooperation", 
                "Philanthropy"=>"Foundations", "Philanthropy"=>"Nonprofits", 
                "Philanthropy"=>"Philanthropy and public policy", 
                "Philanthropy"=>"Venture philanthropy", 
                "Philanthropy"=>"Voluntarism", 
                "Public affairs"=>"Democracy", 
                "Public affairs"=>"Leadership development", 
                "Public affairs"=>"National security", 
                "Public affairs"=>"Public administration", 
                "Public affairs"=>"Public policy", 
                "Public affairs"=>"Public utilities", 
                "Public affairs"=>"Public/private ventures", 
                "Public safety"=>"Abuse prevention", 
                "Public safety"=>"Consumer protection", 
                "Public safety"=>"Corrections and penology", 
                "Public safety"=>"Courts", 
                "Public safety"=>"Crime prevention", 
                "Public safety"=>"Disasters and emergency management", 
                "Public safety"=>"Fire prevention and control",
                "Public safety"=>"Legal services", 
                "Public safety"=>"Safety education", 
                "Religion"=>"Baha'i", 
                "Religion"=>"Buddhism", 
                "Religion"=>"Christianity", 
                "Religion"=>"Confucianism", 
                "Religion"=>"Hinduism", 
                "Religion"=>"Interfaith", 
                "Religion"=>"Islam", 
                "Religion"=>"Judaism", 
                "Religion"=>"Shintoism", 
                "Religion"=>"Sikhism", 
                "Religion"=>"Spirituality", 
                "Religion"=>"Theology", 
                "Religion"=>"Tribal and indigenous religions", 
                "Science"=>"Biology", 
                "Science"=>"Engineering", 
                "Science"=>"Forensic science", 
                "Science"=>"Mathematics", 
                "Science"=>"Physical and earth sciences", 
                "Science"=>"Technology", 
                "Social sciences"=>"Anthropology", 
                "Social sciences"=>"Economics", 
                "Social sciences"=>"Geography", 
                "Social sciences"=>"Interdisciplinary studies",
                "Social sciences"=>"Law", 
                "Social sciences"=>"Paranormal and mystic studies", 
                "Social sciences"=>"Political science", 
                "Social sciences"=>"Population studies", 
                "Social sciences"=>"Psychology and behavioral science", 
                "Social sciences"=>"Sociology", 
                "Sports and recreation"=>"Community recreation", 
                "Sports and recreation"=>"Sports", 
                "Unknown or not classified"=>"Unknown or not classified"}

end
