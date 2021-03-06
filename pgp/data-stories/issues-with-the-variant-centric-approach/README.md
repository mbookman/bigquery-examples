<!-- R Markdown Documentation, DO NOT EDIT THE PLAIN MARKDOWN VERSION OF THIS FILE -->

<!-- Copyright 2014 Madeleine Price Ball -->

<!-- Licensed under the Apache License, Version 2.0 (the "License"); -->
<!-- you may not use this file except in compliance with the License. -->
<!-- You may obtain a copy of the License at -->

<!--     http://www.apache.org/licenses/LICENSE-2.0 -->

<!-- Unless required by applicable law or agreed to in writing, software -->
<!-- distributed under the License is distributed on an "AS IS" BASIS, -->
<!-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. -->
<!-- See the License for the specific language governing permissions and -->
<!-- limitations under the License. -->

Issues with the Variant Centric Approach
========================================

This is a cautionary tale about the "variant call format" - known as
VCF - and how a variant-centric approach poses serious issues for
scientific usability of a genome data database. In this particular
example, we're examining the Harvard Personal Genome Project (PGP)
data as it is currently represented in Google Genomics' BigQuery
database (as of May 16 2014).

This story contains two vignettes based on real world data, an interlude,
a piece of speculative fiction, and a happy conclusion.

1. Frederick can't find participants with Factor V Leiden
2. Thomas confirms the amazing intelligence of PGP participants
3. Interlude: Casey updates the database
4. Emily is confused about variant frequencies
5. Ending: Casey retroactively makes data variant-agnostic
6. Appendix: Queries upon native CGI data

Frederick can't find participants with Factor V Leiden
------------------------------------------------------

Frederick is a new grad student excited by participatory research.
He sees that PGP Harvard participants are sharing both trait
information and genome data, and he's curious if there are
participants with genetic diseases they don't know about.

Fred's last rotation was in a lab that studied how blood clots,
so his first idea is to see if any participants carry
[Factor V Leiden](https://en.wikipedia.org/wiki/Factor_V_Leiden) -
and if so, whether they've reported the trait of
"Hereditary thrombophilia".

Factor V Leiden is caused by a G to A substitution in the protein
coding portion of the Factor V gene, a variation corresponding to
dbSNP ID rs6025. In build 37 this is located at chromosome 1,
position 169519049.

So Frederick runs the following on BigQuery:
```
SELECT
  call.gt,
  COUNT(call.gt) AS cnt,
FROM
  [google.com:biggene:pgp.variants]
WHERE
  ( contig_name = '1' AND
    start_pos = 169519049 )
GROUP BY
  call.gt
ORDER BY
  cnt DESC
```
And Frederick finds:

| call genotype | sample count | Frederick's notes               |
|---------------|--------------|---------------------------------|
| 1/1           | 167          | homozygous for variant genotype |
| 1/0           | 5            | heterozygous carrier of variant |

Frederick is baffled. "A 1 refers to the non-reference variant...
that means 167 participants are homozygous for Factor V Leiden?"

Dr. Brainy overhears and looks over Frederick's shoulder. "Oh,"
she says, "For this variant, the reference genome *has* Factor
V Leiden. So you're looking for people that are 0/0."

"Oooh." says Frederick. "That makes sense. It's pretty rare,
so I guess there aren't any homozygotes in the PGP."

"Well actually," says Dr. Brainy, "We can't tell."

"Why?" asks Frederick.

"Using tools provided by Complete Genomics -- the sequencer
of these genomes -- Google Genomics converted the data into
classic VCF format before loading it," responds Dr. Brainy.
"Unfortunately, the classic VCF format only reports
information where a participant has at least one variant.
So that's what got loaded into the database."

"Wait," responds Frederick. He quickly searches for more
information about the PGP data. "Look, there's 172 genomes
total. 167 and 5 add up to 172 - so we can tell there aren't
any homozygous reference participants."

"That's good. But if those numbers hadn't matched up, we
wouldn't really know if the remainder were homozygous. They
might simply be missing that data, whole genome data always
has some missing regions."

"Oh." Fred frowns. "So, like, we're never sure how many are
homozygous for reference? In any of the PGP data?!" he asks.
"Doesn't this make the data really weird ... maybe unusable...
if you're trying to analyze genotype/trait correlations?"

"I'm afraid so," concludes Dr. Brainy.

Thomas confirms amazing intelligence in the PGP cohort
------------------------------------------------------

Thomas is a precocious undergraduate in the lab who wants to
analyze genomes. He just read about [a variant predicted to
increase IQ by up to six points](http://www.economist.com/news/science-and-technology/21601809-potent-source-genetic-variation-cognitive-ability-has-just-been)!
"Wow," thinks Thomas, "If that's true... I wonder if it's
enriched in PGP participants. They have to pass this
complicated exam to be in the project, so they're probably
smarter than average."

The variation in this study corresponds to dbSNP ID rs9536314,
causing an amino acid substitution in the Klotho gene (KL F327V).
About 30% of people carry the variant. In build 37, this is an T
to G substition at chromosome 13, position 33628138.

So Thomas builds and runs the following on BigQuery:
```
SELECT
  call.gt,
  COUNT(call.gt) AS cnt
FROM
  [google.com:biggene:pgp.variants]
WHERE
  ( contig_name = '13' AND
    start_pos = 33628138 )
GROUP BY
  call.gt
ORDER BY
  cnt DESC
```

And Thomas finds:

| call genotype | sample count | Thomas's notes                          |
|---------------|--------------|-----------------------------------------|
| 1/0           | 32           | participants with 1 copy of the variant |
| 1/1           | 5            | participants with 2 copies of variant   |

"Holy crap!" exclaims Thomas. "Every single participant here has
at least one copy of this variant!"

"This really is the IQ gene, and the participants are hella-smart!"

Dr. Brainy overhears Thomas and smacks her head.

"What?" says Thomas.

Dr. Brainy sighs. "Go show that to Frederick."

Interlude: Casey updates the database
------------------------------------

Over at Google Genomics, Casey hears about the stories of
Thomas and Frederick. With a generous mug of coffee, Casey
gets to work.

Soon the data is updated: the genome imports now include a
step where each genome is examined at all known variant
positions. To do this, Casey creates a list combining all
variant positions in the batch, and those already known
about in the database. Then, matching-reference genotypes
are extracted for these positions (i.e. if the genome had
reference called) and the additional data is added to the
database.

"Problem solved," announces Casey.

Emily is confused about variant frequencies
-------------------------------------------

Emily is a seasoned grad student: she wants to defend,
and she's hoping to dig up some interesting observations
to publish through analysis of online data.

One question Emily thinks to ask: do variant frequencies vary
according to ancestry? For example, does Ashkenazi ancestry
mean fewer rare variants because of a
[bottleneck effect](https://en.wikipedia.org/wiki/Population_bottleneck)?
Using BigQuery to examine PGP and 1000 Genomes data, Emily
starts to plot histograms of variant frequencies in each
genome.

She soon notices a pattern, but it's bizarre. The PGP data is
an ongoing project and, for some reason, the more recent genomes
have fewer very rare variants? How could this be?

Emily suspects it's a data artifact, but she has no explanation.
She brings it to Dr. Brainy.

"Oh... yeah, I thought this might happen," mutters Dr. Brainy.

"Why? Do you know what's causing this phenomenon?" asks Emily.

"It's just that variants and genomes are hard," sighs Dr. Brainy.
"Casey fixed how they import genomes, but it's asymmetric. When
an old genome has a very rare variant, all the new genomes that get
added record that position as matching reference. But when the
new genome has a very rare variant, the opposite isn't true."

"I suppose," she continues, "the proper solution would be to run through
all the original data from the previous genomes to report reference
genotypes for any new variant positions added by the new genome."

"Or maybe actually having a database entry for every position in the
genome? Although how would you handle indels...." Her voice trails off.

"Hey," interjects Emily, "Isn't this like
[confirmation bias](https://en.wikipedia.org/wiki/Confirmation_bias)?
If we only record data for positions where some previous genome had
a variant, that means we'll tend to overestimate variant frequencies,
especially the rare ones? Because they're biased to come from smaller
sample sets."

"Yes," agrees Dr. Brainy, "That's a fair summary."

"This is hard," reflects Emily, "I feel bad for Casey!"

Ending: Casey retroactively makes data variant-agnostic
-------------------------------------------------------

Back at Google Genomics, Casey realizes a better solution for storing
the data. The original Complete Genomics data, and the gVCF format
created by Illumina, both report "matching reference" regions rather
than individual positions. Storing the *regions* in the database, and
reworking database queries to check for such fragments, would provide
the complete solution.

But going back to all the old data to redo data processing is tedious,
so Casey applies for one cycle of Retroactive Messaging time at the
Googleplex (a popular internal feature where you send messages to
your past self). The database is retroactively upgraded.

In Timeline 2, Emily examines the database and finds perfect data, an
interesting finding, and publishes it in PLoS Genetics!

Appendix: Queries upon native CGI data
-------------------------------------------------------------
At a later date, the native CGI data was also loaded into BigQuery.  For more detail, see the [provenance](../../provenance) of table [cgi_variants](https://bigquery.cloud.google.com/table/google.com:biggene:pgp.cgi_variants?pli=1).  Note that this data is for 174 individuals whereas table [variants](https://bigquery.cloud.google.com/table/google.com:biggene:pgp.variants?pli=1) only has data for 172 individuals.




First let's take a look at the data relevant to Klotho:

```
# Sample level data for Klotho variant rs9536314 for use in the "amazing
# intelligence of PGP participants" data story. 
SELECT
  sample_id,
  chromosome,
  locusBegin,
  locusEnd,
  reference,
  allele1Seq,
  allele2Seq,
FROM
  [google.com:biggene:pgp.cgi_variants]
WHERE
  chromosome = "chr13"
  AND locusBegin <= 33628137
  AND locusEnd >= 33628138
ORDER BY
  sample_id
```

Number of rows returned by this query: 174.  We have one row for every indivudual in this dataset.

Examing the first few rows, we see:
<!-- html table generated in R 3.0.2 by xtable 1.7-3 package -->
<!-- Mon Aug  4 18:28:37 2014 -->
<TABLE border=1>
<TR> <TH> sample_id </TH> <TH> chromosome </TH> <TH> locusBegin </TH> <TH> locusEnd </TH> <TH> reference </TH> <TH> allele1Seq </TH> <TH> allele2Seq </TH>  </TR>
  <TR> <TD> hu011C57 </TD> <TD> chr13 </TD> <TD align="right"> 33627829 </TD> <TD align="right"> 33628847 </TD> <TD> = </TD> <TD> = </TD> <TD> = </TD> </TR>
  <TR> <TD> hu016B28 </TD> <TD> chr13 </TD> <TD align="right"> 33628137 </TD> <TD align="right"> 33628138 </TD> <TD> T </TD> <TD> G </TD> <TD> T </TD> </TR>
  <TR> <TD> hu0211D6 </TD> <TD> chr13 </TD> <TD align="right"> 33627829 </TD> <TD align="right"> 33628988 </TD> <TD> = </TD> <TD> = </TD> <TD> = </TD> </TR>
  <TR> <TD> hu025CEA </TD> <TD> chr13 </TD> <TD align="right"> 33627829 </TD> <TD align="right"> 33629513 </TD> <TD> = </TD> <TD> = </TD> <TD> = </TD> </TR>
  <TR> <TD> hu032C04 </TD> <TD> chr13 </TD> <TD align="right"> 33628137 </TD> <TD align="right"> 33628138 </TD> <TD> T </TD> <TD> G </TD> <TD> T </TD> </TR>
  <TR> <TD> hu034DB1 </TD> <TD> chr13 </TD> <TD align="right"> 33627829 </TD> <TD align="right"> 33628988 </TD> <TD> = </TD> <TD> = </TD> <TD> = </TD> </TR>
  <TR> <TD> hu040C0A </TD> <TD> chr13 </TD> <TD align="right"> 33628137 </TD> <TD align="right"> 33628138 </TD> <TD> T </TD> <TD> G </TD> <TD> G </TD> </TR>
  <TR> <TD> hu04DF3C </TD> <TD> chr13 </TD> <TD align="right"> 33627829 </TD> <TD align="right"> 33628988 </TD> <TD> = </TD> <TD> = </TD> <TD> = </TD> </TR>
  <TR> <TD> hu04F220 </TD> <TD> chr13 </TD> <TD align="right"> 33627829 </TD> <TD align="right"> 33628988 </TD> <TD> = </TD> <TD> = </TD> <TD> = </TD> </TR>
  <TR> <TD> hu050E9C </TD> <TD> chr13 </TD> <TD align="right"> 33627829 </TD> <TD align="right"> 33628667 </TD> <TD> = </TD> <TD> = </TD> <TD> = </TD> </TR>
   </TABLE>


And summarizing by genotype:

```
# Sample counts for Klotho variant rs9536314 for use in the "amazing
# intelligence of PGP participants" data story. 
SELECT
  COUNT(sample_id) AS sample_counts,
  chromosome,
  reference,
  allele1Seq,
  allele2Seq,
FROM
  [google.com:biggene:pgp.cgi_variants]
WHERE
  chromosome = "chr13"
  AND locusBegin <= 33628137
  AND locusEnd >= 33628138
GROUP BY
  chromosome,
  reference,
  allele1Seq,
  allele2Seq
ORDER BY
  sample_counts DESC
```


<!-- html table generated in R 3.0.2 by xtable 1.7-3 package -->
<!-- Mon Aug  4 18:28:43 2014 -->
<TABLE border=1>
<TR> <TH> sample_counts </TH> <TH> chromosome </TH> <TH> reference </TH> <TH> allele1Seq </TH> <TH> allele2Seq </TH>  </TR>
  <TR> <TD align="right"> 135 </TD> <TD> chr13 </TD> <TD> = </TD> <TD> = </TD> <TD> = </TD> </TR>
  <TR> <TD align="right">  32 </TD> <TD> chr13 </TD> <TD> T </TD> <TD> G </TD> <TD> T </TD> </TR>
  <TR> <TD align="right">   5 </TD> <TD> chr13 </TD> <TD> T </TD> <TD> G </TD> <TD> G </TD> </TR>
  <TR> <TD align="right">   2 </TD> <TD> chr13 </TD> <TD> = </TD> <TD> ? </TD> <TD> ? </TD> </TR>
   </TABLE>

We see that 135 individuals are homozygous reference but two individuals were no-calls at this genomic position.

Next let's look at the data relevant to Factor V Leiden:

```
# Sample level data for rs6025 and hereditary thrombophilia trait  
# for use in the Factor V Leiden data story. 
 SELECT
  sample_id,
  chromosome,
  locusBegin,
  locusEnd,
  reference,
  allele1Seq,
  allele2Seq,
  zygosity,
  has_Hereditary_thrombophilia_includes_Factor_V_Leiden_and_Prothrombin_G20210A AS has_Hereditary_thrombophilia
FROM
  [google.com:biggene:pgp.cgi_variants] AS var
LEFT OUTER JOIN
  [google.com:biggene:pgp.phenotypes] AS pheno
ON
  pheno.Participant = var.sample_id
  WHERE
  chromosome = 'chr1'
  AND locusBegin <= 169519048
  AND locusEnd >= 169519049
ORDER BY
  sample_id
```

Number of rows returned by this query: 174.

Examing the first few rows, we see:
<!-- html table generated in R 3.0.2 by xtable 1.7-3 package -->
<!-- Mon Aug  4 18:28:48 2014 -->
<TABLE border=1>
<TR> <TH> sample_id </TH> <TH> chromosome </TH> <TH> locusBegin </TH> <TH> locusEnd </TH> <TH> reference </TH> <TH> allele1Seq </TH> <TH> allele2Seq </TH> <TH> zygosity </TH> <TH> has_Hereditary_thrombophilia </TH>  </TR>
  <TR> <TD> hu011C57 </TD> <TD> chr1 </TD> <TD align="right"> 169519048 </TD> <TD align="right"> 169519049 </TD> <TD> T </TD> <TD> C </TD> <TD> C </TD> <TD> hom </TD> <TD>  </TD> </TR>
  <TR> <TD> hu016B28 </TD> <TD> chr1 </TD> <TD align="right"> 169519048 </TD> <TD align="right"> 169519049 </TD> <TD> T </TD> <TD> C </TD> <TD> C </TD> <TD> hom </TD> <TD>  </TD> </TR>
  <TR> <TD> hu0211D6 </TD> <TD> chr1 </TD> <TD align="right"> 169519048 </TD> <TD align="right"> 169519049 </TD> <TD> T </TD> <TD> C </TD> <TD> C </TD> <TD> hom </TD> <TD>  </TD> </TR>
  <TR> <TD> hu025CEA </TD> <TD> chr1 </TD> <TD align="right"> 169519048 </TD> <TD align="right"> 169519049 </TD> <TD> T </TD> <TD> C </TD> <TD> C </TD> <TD> hom </TD> <TD>  </TD> </TR>
  <TR> <TD> hu032C04 </TD> <TD> chr1 </TD> <TD align="right"> 169519048 </TD> <TD align="right"> 169519049 </TD> <TD> T </TD> <TD> C </TD> <TD> C </TD> <TD> hom </TD> <TD>  </TD> </TR>
  <TR> <TD> hu034DB1 </TD> <TD> chr1 </TD> <TD align="right"> 169519048 </TD> <TD align="right"> 169519049 </TD> <TD> T </TD> <TD> C </TD> <TD> C </TD> <TD> hom </TD> <TD>  </TD> </TR>
  <TR> <TD> hu040C0A </TD> <TD> chr1 </TD> <TD align="right"> 169519048 </TD> <TD align="right"> 169519049 </TD> <TD> T </TD> <TD> C </TD> <TD> C </TD> <TD> hom </TD> <TD>  </TD> </TR>
  <TR> <TD> hu04DF3C </TD> <TD> chr1 </TD> <TD align="right"> 169519048 </TD> <TD align="right"> 169519049 </TD> <TD> T </TD> <TD> C </TD> <TD> C </TD> <TD> hom </TD> <TD>  </TD> </TR>
  <TR> <TD> hu04F220 </TD> <TD> chr1 </TD> <TD align="right"> 169519048 </TD> <TD align="right"> 169519049 </TD> <TD> T </TD> <TD> C </TD> <TD> C </TD> <TD> hom </TD> <TD>  </TD> </TR>
  <TR> <TD> hu050E9C </TD> <TD> chr1 </TD> <TD align="right"> 169519048 </TD> <TD align="right"> 169519049 </TD> <TD> T </TD> <TD> C </TD> <TD> C </TD> <TD> hom </TD> <TD>  </TD> </TR>
   </TABLE>


And summarizing by genotype:

```
# Summary data for rs6025 and hereditary thrombophilia trait  
# for use in the Factor V Leiden data story. 
 SELECT
  COUNT(sample_id) AS sample_counts,
  chromosome,
  reference,
  allele1Seq,
  allele2Seq,
  has_Hereditary_thrombophilia_includes_Factor_V_Leiden_and_Prothrombin_G20210A AS has_Hereditary_thrombophilia
FROM
  [google.com:biggene:pgp.cgi_variants] AS var
LEFT OUTER JOIN
  [google.com:biggene:pgp.phenotypes] AS pheno
ON
  pheno.Participant = var.sample_id
  WHERE
  chromosome = 'chr1'
  AND locusBegin <= 169519048
  AND locusEnd >= 169519049
GROUP BY
  chromosome,
  reference,
  allele1Seq,
  allele2Seq,
  has_Hereditary_thrombophilia
ORDER BY
  sample_counts DESC
```


<!-- html table generated in R 3.0.2 by xtable 1.7-3 package -->
<!-- Mon Aug  4 18:28:53 2014 -->
<TABLE border=1>
<TR> <TH> sample_counts </TH> <TH> chromosome </TH> <TH> reference </TH> <TH> allele1Seq </TH> <TH> allele2Seq </TH> <TH> has_Hereditary_thrombophilia </TH>  </TR>
  <TR> <TD align="right"> 169 </TD> <TD> chr1 </TD> <TD> T </TD> <TD> C </TD> <TD> C </TD> <TD>  </TD> </TR>
  <TR> <TD align="right">   5 </TD> <TD> chr1 </TD> <TD> T </TD> <TD> C </TD> <TD> T </TD> <TD>  </TD> </TR>
   </TABLE>

We see that no individuals are homozygous reference and no one responded _true_ for the _Hereditary thrombophilia includes Factor V Leiden and Prothrombin G20210A_ trait.
