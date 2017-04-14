# -*- coding: utf-8 -*-
   
import numpy as np
import sys
import os
import numpy
import struct

def parse_arguments(arg_elements):
    args = {}
    arg_num = int(len(arg_elements) / 2)

    for i in range(arg_num):
        key = arg_elements[2*i].replace("--","").replace("-", "_");
        args[key] = arg_elements[2*i+1]
    ## // for()
    return args
## // parse_arguments()


def str2bool(v):
  return v.lower() in ("yes", "true", "t", "1")
## // str2bool() 

def writeUtterance(uttId, featMat, ark, encoding):
    featMat = numpy.asarray(featMat, dtype=numpy.float32)
    m,n = featMat.shape
    ## Write header
    ark.write(struct.pack('<%ds'%(len(uttId)),uttId.encode(encoding)))
    ark.write(struct.pack('<cxcccc',' '.encode(encoding),'B'.encode(encoding),
                'F'.encode(encoding),'M'.encode(encoding),' '.encode(encoding)))
    ark.write(struct.pack('<bi', 4, m))
    ark.write(struct.pack('<bi', 4, n))
    ## Write feature matrix
    ark.write(featMat)



# ============================================================================
#                                 Global constant
# ============================================================================  
K_RAND_RANGE = 100
K_MAX_NUM_OF_ZEROS = 20
K_MAX_NUM_OF_ONES = 10

K_FEATS_DIM = 10

if __name__ == '__main__':
    # check the arguments
    arg_elements = [sys.argv[i] for i in range(1, len(sys.argv))]
    arguments = parse_arguments(arg_elements)
    required_arguments = ['num_utt', 'frm_per_utt', 'overwrite_text', 'overwrite_feats', 'output_dir']

    for essential_arg in required_arguments:
        if essential_arg in arguments == False:
            print('Error: the argument %s has to be specified') % (arg)
            exit(1)
    # // for args

    num_utt = int(arguments['num_utt'])
    frm_per_utt = int(arguments['frm_per_utt'])
    overwrite_text = str2bool(arguments['overwrite_text'])
    overwrite_feats = str2bool(arguments['overwrite_feats'])
    output_dir = arguments['output_dir']
    
    os.makedirs(output_dir + "/feats", exist_ok=True)
 
    utt_id_list = ["utt_0{}A".format(i) for i in range(0, num_utt)]
    
    
    # ============================================================================
    #                                 utt2spk
    # ============================================================================    
    fp_utt2spk = open(output_dir + "/utt2spk", "w")
    for utt_id in utt_id_list:
        fp_utt2spk.write("{} {}\n".format(utt_id, utt_id))
    ## // end write utt2spk
    
    # ============================================================================
    #                                 text
    # ============================================================================    
    if overwrite_text :
        fp_text = open(output_dir + "/text", "w")
        
        for utt_id in range(0, num_utt):
           fp_text.write("utt_0{}A ".format(utt_id))
           this_utt_sequence = []
        
           ## 限制每個utterance至少會有各一個0與1
           rand_num_of_zeros = (np.random.randint(1, high=K_RAND_RANGE) % K_MAX_NUM_OF_ZEROS) + 1
           rand_num_of_ones = (np.random.randint(1, high=K_RAND_RANGE) % K_MAX_NUM_OF_ONES) + 1 

           this_utt_sequence = [0] * rand_num_of_zeros + [1] * rand_num_of_ones + [0] * rand_num_of_zeros
           this_utt_sequence = list(map(str, this_utt_sequence))
           str_utt_sequence = " ".join(this_utt_sequence)
           str_utt_sequence = str_utt_sequence.replace("0", "N")
           str_utt_sequence = str_utt_sequence.replace("1", "A")
           
           fp_text.write("{}\n".format(str_utt_sequence))
        ## end for generate utterances
        print("(LOG) Successfully generate {}! Total {} utterances".format(output_dir + "/text", num_utt))
        
        fp_text.close()
    ## // end  overwrite_text == True
    
    # ============================================================================
    #                             feats.scp & feats.ark
    # ============================================================================  
    
    if overwrite_feats :
        fp_scp = open(output_dir + "/feats.scp", "w")
        
        for  i, utt_id in enumerate(utt_id_list) :
            ## Generate feats.scp, 
            ## CAUTION!!!! 記得最後要加上特徵開始的位置(例如你的utt_id長度是5, 那你的feats.scp裡面其中一行 XXXXX path-to-ark:6), 不然會有錯
            this_utt_ark_path = output_dir + "/feats/{}_feats.ark:{}".format(utt_id, len(utt_id)+1)            
            fp_scp.write("{} {}\n".format(utt_id, this_utt_ark_path))
            
            ## 只有feats.scp需要ark:6, 存檔的時候不用
            this_utt_ark_path = output_dir + "/feats/{}_feats.ark".format(utt_id)
            
            ## --------------------
            # ## (1) Generate feats.ark, ark files are text format:
            # fp_ark = open(this_utt_ark_path, "w")
            # feat_matrix = np.random.rand(frm_per_utt, K_FEATS_DIM)
            # ## 格式: 
            # ## <UTT_ID> [
            # ##   <FRAME_1_FEATS>
            # ##   <FRAME_2_FEATS>
            # ##    ...
            # ##   <LAST_FRAME_FEATS> ]
            # fp_ark.write("{}  [\n".format(utt_id))
            
            # for index, row in enumerate(feat_matrix):             
                # row_list = list(map(str, row.tolist()))
                # row_str = " ".join(row_list)
                
                # if index + 1 == frm_per_utt:
                    # fp_ark.write("  {} ]\n".format(row_str))
                # else:
                    # fp_ark.write("  {}\n".format(row_str))
            # ## // end for write feats.ark
            
            # fp_ark.close()
            ## ----------------
            
            ## (2)  Generate feats.ark, ark files are binary format:
            feat_matrix = np.random.rand(frm_per_utt, K_FEATS_DIM)
            fp_ark = open(this_utt_ark_path, "wb")
            writeUtterance(utt_id, feat_matrix, fp_ark, "UTF-8")
        ## // end for
        
        fp_scp.close()
    ## // overwrite_feats == True
    
## end if __name__ == '__main__'