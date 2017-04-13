export KALDI_ROOT=/usr/local/kaldi
export LC_ALL=C
export IRSTLM=$KALDI_ROOT/tools/irstlm
export SRILM=$KALDI_ROOT/tools/srilm/bin/i686-m64
export SPH2PIPE=$KALDI_ROOT/tools/sph2pipe_v2.5

export PATH=$PATH:$SPH2PIPE
export PATH=$PATH:$IRSTLM:$IRSTLM/bin
export PATH=$PATH:$SRILM
export PATH=$PATH:$KALDI_ROOT/egs/wsj/s5/utils
export PATH=$PATH:$KALDI_ROOT/src/bin
export PATH=$PATH:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/src/fstbin
export PATH=$PATH:$KALDI_ROOT/src/gmmbin/:$KALDI_ROOT/src/featbin
export PATH=$PATH:$KALDI_ROOT/src/lm/:$KALDI_ROOT/src/sgmmbin
export PATH=$PATH:$KALDI_ROOT/src/sgmm2bin/:$KALDI_ROOT/src/fgmmbin
export PATH=$PATH:$KALDI_ROOT/src/latbin/:$KALDI_ROOT/src/nnetbin
export PATH=$PATH:$KALDI_ROOT/src/nnet2bin/:$KALDI_ROOT/src/kwsbin
export PATH=$PATH:$KALDI_ROOT/src/online2bin/:$KALDI_ROOT/src/ivectorbin
export PATH=$PATH:$KALDI_ROOT/src/lmbin