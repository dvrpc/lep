CREATE TABLE table_name_lep AS
WITH
    a AS (
        SELECT
            *,
            spanish_lim + french_haitian_or_cajun_lim + german_or_other_west_germanic_languages_lim + russian_polish_or_other_slavic_languages_lim + other_indo_european_languages_lim + korean_lim + chinese_mandarin_cantonese_lim + vietnamese_lim + tagalog_filipino_lim + other_asian_and_pacific_island_languages_lim + arabic_lim AS tt_pop_lep_e
        FROM
            main.table_name_C16001
    ),
    b AS (
        SELECT
            *,
            CASE
                WHEN estimatetotal * 0.05 < spanish_lim THEN TRUE
                ELSE FALSE
            END AS splime_5p,
            CASE
                WHEN estimatetotal * 0.05 < french_haitian_or_cajun_lim THEN TRUE
                ELSE FALSE
            END AS frlime_5p,
            CASE
                WHEN estimatetotal * 0.05 < german_or_other_west_germanic_languages_lim THEN TRUE
                ELSE FALSE
            END AS gelime_5p,
            CASE
                WHEN estimatetotal * 0.05 < russian_polish_or_other_slavic_languages_lim THEN TRUE
                ELSE FALSE
            END AS rulime_5p,
            CASE
                WHEN estimatetotal * 0.05 < other_indo_european_languages_lim THEN TRUE
                ELSE FALSE
            END AS inlime_5p,
            CASE
                WHEN estimatetotal * 0.05 < korean_lim THEN TRUE
                ELSE FALSE
            END AS kolime_5p,
            CASE
                WHEN estimatetotal * 0.05 < chinese_mandarin_cantonese_lim THEN TRUE
                ELSE FALSE
            END AS chlime_5p,
            CASE
                WHEN estimatetotal * 0.05 < vietnamese_lim THEN TRUE
                ELSE FALSE
            END AS vilime_5p,
            CASE
                WHEN estimatetotal * 0.05 < tagalog_filipino_lim THEN TRUE
                ELSE FALSE
            END AS talime_5p,
            CASE
                WHEN estimatetotal * 0.05 < other_asian_and_pacific_island_languages_lim THEN TRUE
                ELSE FALSE
            END AS palime_5p,
            CASE
                WHEN estimatetotal * 0.05 < arabic_lim THEN TRUE
                ELSE FALSE
            END AS arlime_5p
        FROM
            a
    )
		SELECT 
			*,
		    CASE
		        WHEN spanish_lim = max_lim THEN 'spanish'
		        WHEN french_haitian_or_cajun_lim = max_lim THEN 'french_haitian_or_cajun'
		        WHEN german_or_other_west_germanic_languages_lim = max_lim THEN 'german_or_other_west_germanic'
		        WHEN russian_polish_or_other_slavic_languages_lim = max_lim THEN 'russian_polish_or_other_slavic'
		        WHEN other_indo_european_languages_lim = max_lim THEN 'other_indo_european'
		        WHEN korean_lim = max_lim THEN 'korean'
		        WHEN chinese_mandarin_cantonese_lim = max_lim THEN 'chinese_mandarin_cantonese'
		        WHEN vietnamese_lim = max_lim THEN 'vietnamese'
		        WHEN tagalog_filipino_lim = max_lim THEN 'tagalog_filipino'
		        WHEN other_asian_and_pacific_island_languages_lim = max_lim THEN 'other_asian_and_pacific_island'
		        WHEN arabic_lim = max_lim THEN 'arabic'
		        ELSE NULL
		    END AS top_lep_la
		FROM (
		    SELECT
		        *,
		        GREATEST(
		            spanish_lim,
		            french_haitian_or_cajun_lim,
		            german_or_other_west_germanic_languages_lim,
		            russian_polish_or_other_slavic_languages_lim,
		            other_indo_european_languages_lim,
		            korean_lim,
		            chinese_mandarin_cantonese_lim,
		            vietnamese_lim,
		            tagalog_filipino_lim,
		            other_asian_and_pacific_island_languages_lim,
		            arabic_lim
		        ) AS max_lim
		    FROM b
		) AS max_lim;