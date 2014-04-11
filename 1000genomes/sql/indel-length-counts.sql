SELECT
  length_difference,
  COUNT(length_difference) AS count_of_indels_with_length_difference,
FROM (
  SELECT
    contig,
    position,
    reference_bases,
    LENGTH(reference_bases) AS ref_length,
    alternate_bases AS allele,
    LENGTH(alternate_bases) AS allele_length,
    (LENGTH(alternate_bases) - LENGTH(reference_bases)) AS length_difference,
    FROM
      [google.com:biggene:1000genomes.variants1kG]
    WHERE
      vt ='INDEL'
    )
GROUP BY
  length_difference
ORDER BY
  length_difference;
