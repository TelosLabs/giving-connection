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

  SERVICES = ["Advocacy", "Human & Civil Rights", 
              "Animals", 
              "Arts & Culture", 
              "Clothing", 
              "Community & Economic Development", 
              "Children & Family Services", 
              "Disability Services & Advocates", 
              "Disaster Relief & Preparedness", 
              "Drug & Alcohol Treatment", 
              "Education", 
              "Emergency", "Safety & Legal Related", 
              "Employment", 
              "Environment", 
              "Faith-Based", 
              "Inmate & Formerly Incarcerated Services", 
              "Housing & Homelessness ", 
              "Hunger & Food Security", 
              "Immigrant & Refugee Services", 
              "International", 
              "Justice & Legal Services", 
              "LGBTQ+", 
              "Health ", 
              "Media & Broadcasting", 
              "Mental Health ", 
              "Philanthropy", 
              "Race & Ethnicity", 
              "Research & Public Policy", 
              "Science", 
              "Social Sciences", 
              "Human & Social Services", 
              "Seniors", 
              "Sports & Recreation", 
              "Transportation", 
              "Veteran Services ", 
              "Women's Rights", 
              "Youth Development"  ]

  CATEGORIES = ["Advocacy", "Human & Civil Rights", 
                "Animals", 
                "Arts & Culture", 
                "Clothing", 
                "Community & Economic Development", 
                "Children & Family Services", 
                "Crisis Support", 
                "Disability Services & Advocates", 
                "Disaster Relief", 
                "Drug & Alcohol Treatment", 
                "Education", 
                "Emergency & Safety", 
                "Employment", 
                "Environment", 
                "Faith-Based", 
                "Formerly Incarcerated ", 
                "Housing & Homelessness ", 
                "Hunger", 
                "Immigrant & Refugee Services", 
                "Information & Communications", 
                "International", 
                "Justice & Legal Services", 
                "Living Essentials ", 
                "LGBTQ+", 
                "Health ", 
                "Media & Broadcasting", 
                "Mental Health ", 
                "Philanthropy", 
                "Race & Ethnicity", 
                "Research & Public Policy", 
                "Science", 
                "Social Sciences", 
                "Human & Social Services", 
                "Seniors", 
                "Sports & Recreation", 
                "Transportation", 
                "Veteran Services ", 
                "Women's Rights" ]

    BENEFICIARIES = { 
                    "Age" => [ "Adults", "Children and Youth" ],
                    "Ethnic and Racial Groups" => 
                                  [ "Indigenous peoples", "Multiracial people", "People of African descent", 
                                    "People of Asian descent", "People of European descent", 
                                    "People of Latin American descent", "People of Middle Eastern descent" ],
                    "Family Relationships" => [ "Caregivers", "Families", "Non-adults", "Parents", 
                                                "Widows and widowers" ],
                    "Gender and Sexual Identity" =>  [ "Heterosexuals", "Intersex People", "LGBTQ People", 
                                                       "Men and Boys", "Women and girls" ],
                    "Health" => [ "People with disabilities", "People with diseases and illness", 
                                  "Pregnant people", "People with substance abuse issues" ],
                    "Religious Groups" => [ "Baha'is", "Buddhists", "Christians", 
                                            "Confucists", "Hindus", "Interfaith groups", 
                                            "Jewish People", "Muslims", "Secular groups", 
                                            "Shintos", "Sikhs", "Tribal and indigenous religivous groups" ],
                    "Social and Economic Status" => [ "At-risk youth", "Economically disavantaged people", 
                                                      "Immigrants and migrants", "Incarcerated people", 
                                                      "Nomadic People", "Victims and oppressed people (victims of conflict and war, victims of crime and abuse, victims of disaster)" ],
                    "Work and Status Occupations" => [ "Academics", "Activists", "Artists and performers", 
                                                       "Domestic workers", "Emergency responders", "Farmers", 
                                                       "Military personnel", "Retired people", "Self employed people", 
                                                       "Sex workers", "Unemployed people", "Veterans" ] }
                                                    
end

