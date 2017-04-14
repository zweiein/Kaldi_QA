#!/bin/bash

. cmd.sh
. path.sh

data_dir=data/toy
lang_test_dir=data/lang_test


train_nj=4
decode_nj=4

stage=12

if [ $stage -le 0 ]; then
    echo ============================================================================
    echo "               Pseudo Features and Labels Preparation                     "
    echo ============================================================================
    ## (1)事先準備 特徵和 label (例如: data/toy/text, data/toy/wav.scp, data/toy/feats.scp)
    mkdir -p $data_dir

    pwd=`pwd`
    ## 如果第一次執行, --overwrite-text 與--overwrite-feats 要設定為true
    python local/prep_toy_data.py  --num-utt 20  --frm-per-utt 150  --overwrite-text false  --overwrite-feats false --output-dir $pwd/$data_dir

    cp $data_dir/feats.scp  $data_dir/wav.scp  
    utils/utt2spk_to_spk2utt.pl data/toy/utt2spk > data/toy/spk2utt 
    steps/compute_cmvn_stats.sh $data_dir  exp/make_cmvn/toy $data_dir/feats
fi



if [ $stage -le 2 ]; then
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
fi



if [ $stage -le 4 ]; then
    echo ============================================================================
    echo "                           Lang Preparation                     "
    echo ============================================================================
    ## (2)事先準備lang
    utils/prepare_lang.sh  --position-dependent-phones  false  --num-sil-states 1  --num-nonsil-states 1 \
      $dict_dir "SIL" data/local/lang_tmp  data/lang
fi



if [ $stage -le 6 ]; then
    echo ============================================================================
    echo "                        Language Model Preparation                     "
    echo ============================================================================
    ## (3)用(1)訓練Language Model得到 G.txt
    tmpdir=data/tmp
    mkdir -p $tmpdir

    cut -d' ' -f2- $data_dir/text  | sed -e 's:^:<s> :' -e 's:$: </s>:' \
        > $tmpdir/lm_train.text

        
    build-lm.sh -i $tmpdir/lm_train.text -n 2 \
        -o $tmpdir/lm_phone_bg.ilm.gz
     
    gunzip -c $tmpdir/lm_phone_bg.ilm.gz >  $tmpdir/lm_phone_bg.ilm.txt 
     
    compile-lm $tmpdir/lm_phone_bg.ilm.gz -t=yes /dev/stdout | \
        grep -v unk | gzip -c > $tmpdir/lm_phone_bg.arpa.gz     
       
fi      
       
       
       
if [ $stage -le 8 ]; then       
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
                 
    fstisstochastic $lang_test_dir/G.fst


    mkdir -p ${tmpdir}.g
    awk '{if(NF==1){ printf("0 0 %s %s\n", $1,$1); }} END{print "0 0 #0 #0"; print "0";}' \
        < data/local/dict/lexicon.txt  > ${tmpdir}.g/select_empty.fst.txt

    fstcompile --isymbols=$lang_test_dir/words.txt --osymbols=$lang_test_dir/words.txt ${tmpdir}.g/select_empty.fst.txt | \
        fstarcsort --sort_type=olabel | fstcompose - $lang_test_dir/G.fst > ${tmpdir}.g/empty_words.fst

    fstinfo ${tmpdir}.g/empty_words.fst | grep cyclic | grep -w 'y' && echo "Language model has cycles with empty words" && exit 1

    rm -r $tmpdir.g
fi
         

if [ $stage -le 10 ]; then         
    echo ============================================================================
    echo "              Training Monophone GMM & Make Grape                    "
    echo ============================================================================
    ## (5)Train Monophone GMM
    steps/train_mono.sh  --nj "$train_nj"  data/toy  data/lang  exp/mono

    utils/mkgraph.sh data/lang_test  exp/mono  exp/mono/graph
    
fi

 

if [ $stage -le 12 ]; then
    #### 此處需要用python 2.7執行
    echo ============================================================================
    echo "                        Decode (Training set)                     "
    echo ============================================================================
    local/decode.sh --nj "$decode_nj"  exp/mono/graph  data/toy  exp/mono/decode_toy
fi



if [ $stage -le 14 ]; then
    for x in exp/mono/decode_toy; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
fi


exit 1 ;


RESULT:
%WER 51.68 [ 262 / 507, 0 ins, 262 del, 0 sub ] exp/mono/decode_toy/wer_7

