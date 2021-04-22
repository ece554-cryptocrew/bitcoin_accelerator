import hashlib

# string(s) -> bytes(b): b = s.encode()
# bytes(b) -> hex(h): h = b.hex()
# hex(h) -> bytes(b): b = bytes.fromhex(h)
# bytes(b) -> string(s): s = b.decode()
# hexdigest(): hash object -> hex string

hash_vals = []

with open('./hash_in.txt', 'r') as f_in:
    for line in f_in:
        hex_str = line.strip() # assume hex
        byte_str = bytes.fromhex(hex_str) # to bytes
        hash = hashlib.sha256(bytes.fromhex(hashlib.sha256(byte_str).hexdigest())).hexdigest() # hashing
        hash_vals.append(hash) # store hash value

with open('./simu_out_std.txt', 'w') as f_out:
    f_out.writelines('%s\n' % h for h in hash_vals)

