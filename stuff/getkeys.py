#---------------------------------------------------------------------
#    Simple IDA script to extract RSA private keys and certificates.
#    kyprizel, 2010
#
#    Based on original idea and PoC by Tobias Klein
#    http://www.trapkit.de/research/sslkeyfinder/
#---------------------------------------------------------------------
import os
import idaapi
from idautils import *

#OUTFOLDER = 'c:\\temp\\'
OUTFOLDER = os.path.dirname(GetInputFilePath())

patterns = (
    dict(name='X.509 Public Key Infrastructure Certificates',
        sig='30 82 ? ? 30 82 ? ?',
        outfile='%s.crt'
    ),
    dict(name='PKCS #8: Private-Key Information Syntax Standard',
        sig='30 82 ? ? 02 01 00',
        outfile='%s.key'
    ),)

def find_sig(next_seg, pat, dump_cb):
    """
    Scan binary image for pattern and run dump callback function.

    @param next_seg:   Start address
    @param pat:        Dict with config
    @param dump_cb:    Certificate dump callback
    """
    ea = SegStart(next_seg)
    seg_end = SegEnd(next_seg)
    Message('Searching for %s\n' % pat['name'])
#    Message('Current Seg %s\n' % SegName(next_seg))
    while next_seg != BADADDR:
        ea = idaapi.find_binary(ea, seg_end, pat['sig'], 16, 1)
        if ea != BADADDR:
            ea = dump_cb(ea, pat)
        else:
            next_seg = ea = NextSeg(seg_end)
            seg_end = SegEnd(next_seg)


def dump_func(ea, pat):
    """
    Dumps certificate/key from target address to file.

    @param ea:   Target address
    @param pat:  Dict with config

    @return: address to continue search
    """
    size = (Byte(ea+2) << 8 & 0xffff) + Byte(ea+3)
    outfile = os.path.join(OUTFOLDER, pat['outfile'] % str(ea))
    Message('found at %s, size: %d, saved: %s\n' % (atoa(ea), size, outfile))
    SaveFile(outfile, 0, ea, size+4)
    return ea+size+4

for pat in patterns:
    find_sig(FirstSeg(), pat, dump_func)

Message('Key scan complete.\n')
