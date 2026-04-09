# Kudurru Kings — Image Layer Update

This update adds card-image layer asset references to the current live and production CSVs and updates doctrine to define the layered render format.

Updated files:
- `Gameplay_docturine.md`
- `Kudurru_Kings_Final_Engineering_and_Data_Doctrine_v1_1.md`
- `master.csv`
- `production_master.csv`

Layer model:
- background color by family
- border by rarity
- shared background image
- shared main/template layer

Ultra rule:
- Ultra cards use `back_color_ultra.png`
- Ultra cards use `border_ultra.png`
