#!/bin/bash

. cmd.sh
. path.sh

data_dir=data/toy
lang_test_dir=data/lang_test


train_nj=4


echo ============================================================================
echo "               Pseudo Features and Labels Preparation                     "
echo ============================================================================
## (1)事先準備 特徵和 label (例如: data/toy/text, data/toy/wav.scp, data/toy/feats.scp)
mkdir -p $data_dir

pwd=`pwd`
python local/prep_toy_data.py  --num-utt 20  --frm-per-utt 150  --overwrite-text true  --overwrite-feats true --output-dir $pwd/$data_dir

cp $data_dir/feats.scp  $data_dir/wav.scp  

utils/utt2spk_to_spk2utt.pl data/toy/utt2spk > data/toy/spk2utt 

steps/compute_cmvn_stats.sh $data_dir  exp/make_cmvn/toy $data_dir/feats


echo ============================================================================
echo "                           Dict Preparation                     "
echo ============================================================================
dict_dir=data/local/dict
mkdir -p $dict_dir

## 2個phone
# touch $dict_dir/extra_questions.txt
# echo "A" > $dict_dir/nonsilence_phones.txt
# echo "SIL" > $dict_dir/optional_silence.txt
# echo "SIL" > $dict_dir/silence_phones.txt

# echo "SIL SIL" > $dict_dir/lexicon.txt
# echo "A A" >> $dict_dir/lexicon.txt


touch $dict_dir/extra_questions.txt
echo -e "N\nA" > $dict_dir/nonsilence_phones.txt
echo "SIL" > $dict_dir/optional_silence.txt
echo "SIL" > $dict_dir/silence_phones.txt

echo -e "SIL SIL\nN N\nA A" > $dict_dir/lexicon.txt


echo ============================================================================
echo "                           Lang Preparation                     "
echo ============================================================================
## (2)事先準備lang
utils/prepare_lang.sh  --position-dependent-phones  false  $dict_dir "SIL" data/local/lang_tmp  data/lang



echo ============================================================================
echo "                        Language Model Preparation                     "
echo ============================================================================
## (3)用(1)訓練Language Model得到 G.txt
tmpdir=data/tmp
mkdir -p $tmpdir

cut -d' ' -f2- $data_dir/text  | sed -e 's:^:<s> :' -e 's:$: </s>:' \
    > $tmpdir/text_without_uttid.txt

cat data/lang/phones.txt | awk '!($2="")' > $tmpdir/phones_per_line.txt

    
build-lm.sh -i $tmpdir/phones_per_line.txt -n 2 \
  -o $tmpdir/lm_phone_bg.ilm.gz
 
compile-lm $tmpdir/lm_phone_bg.ilm.gz -t=yes /dev/stdout | \
grep -v unk | gzip -c > $tmpdir/lm_phone_bg.arpa.gz     
       
  
       
echo ============================================================================
echo "                          G.fst Preparation                     "
echo ============================================================================
## (4)準備G.fst
mkdir -p $lang_test_dir
cp -R   data/lang/*   $lang_test_dir

gunzip -c $tmpdir/lm_phone_bg.arpa.gz >  $tmpdir/lm_phone_bg.arpa.txt

gunzip -c $tmpdir/lm_phone_bg.arpa.gz | python local/filter_eps.py | \
    arpa2fst --disambig-symbol=#0 \
             --read-symbol-table=$lang_test_dir/words.txt - $lang_test_dir/G.fst
             

             
echo ============================================================================
echo "                           Training Monophone GMM                     "
echo ============================================================================
## (5)Train Monophone GMM
steps/train_mono.sh  --nj "$train_nj"  data/toy  data/lang  exp/mono
