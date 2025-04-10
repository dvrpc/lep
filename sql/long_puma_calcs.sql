WITH
    a AS (
        unpivot (
            SELECT
                spanish_lim AS spanish,
                chinese_mandarin_cantonese_lim AS chinese,
                vietnamese_lim AS vietnamese,
                russian_lim AS russian,
                korean_lim AS korean,
                gujarati_lim AS gujarati,
                haitian_lim AS haitian,
                arabic_lim AS arabic,
                italian_lim AS italian,
                other_indo_european_languages_lim AS other_indo,
                french_cajun_lim AS french_cajun,
                portuguese_lim AS portuguese,
                german_lim AS german,
                yiddish_pennsylvania_dutch_or_other_west_germanic_languages_lim AS yiddish_padutch,
                greek_lim AS greek,
                polish_lim AS polish,
                serbo_croatian_lim AS serbo_croatian,
                ukrainian_or_other_slavic_languages_lim AS ukrainian,
                armenian_lim AS armenian_lim,
                persian_farsi_dari_lim AS persian_farsi,
                hindi_lim AS hindi,
                urdu_lim AS urdu,
                punjabi_lim AS punjabi,
                bengali_lim AS bengali,
                nepali_marathi_or_other_indic_languages_lim AS nepali_marathi,
                telugu_lim AS telugu,
                tamil_lim AS tamil,
                malayalam_kannada_or_other_dravidian_languages_lim AS malayalam_kannada,
                japanese_lim AS japanese,
                hmong_lim AS hmong,
                khmer_lim AS khmer,
                thai_lao_or_other_tai_kadai_languages_lim AS thai_lao,
                other_languages_of_asia_lim AS other_asian,
                tagalog_filipino_lim AS tagalog_filipino,
                ilocano_samoan_hawaiian_or_other_austronesian_languages_lim AS ilocano_samoan_hawaiian,
                hebrew_lim AS hebrew,
                amharic_somali_or_other_afro_asiatic_languages_lim AS amharic_somali,
                yoruba_twi_igbo_or_other_languages_of_western_africa_lim AS yoruba_twi_igbo,
                swahili_or_other_languages_of_central_eastern_and_southern_africa_lim AS swahili_other,
                navajo_lim AS navajo,
                other_native_languages_of_north_america_lim AS other_native_american,
                other_and_unspecified_languages_lim AS other_unspecified
            FROM
                public_use_microdata_area_B16001 c
        ) ON spanish,
        chinese,
        vietnamese,
        russian,
        korean,
        gujarati,
        haitian,
        arabic,
        italian,
        other_indo,
        french_cajun,
        portuguese,
        german,
        yiddish_padutch,
        greek,
        polish,
        serbo_croatian,
        ukrainian,
        armenian_lim,
        persian_farsi,
        hindi,
        urdu,
        punjabi,
        bengali,
        nepali_marathi,
        telugu,
        tamil,
        malayalam_kannada,
        japanese,
        hmong,
        khmer,
        thai_lao,
        other_asian,
        tagalog_filipino,
        ilocano_samoan_hawaiian,
        hebrew,
        amharic_somali,
        yoruba_twi_igbo,
        swahili_other,
        navajo,
        other_native_american,
        other_unspecified
    ),
    b AS (
        SELECT
            a.name,
            SUM(a.value) AS lep_total
        FROM
            a
        GROUP BY
            NAME
        ORDER BY
            SUM(a.value) DESC
    )
SELECT
    *,
    lep_total / (
        SELECT
            SUM(estimatetotal)
        FROM
            public_use_microdata_area_B16001 c
    ) * 100 AS percent_total,
    lep_total / (
        SELECT
            SUM(a.value)
        FROM
            a
    ) * 100 AS percent_lep
FROM
    b;