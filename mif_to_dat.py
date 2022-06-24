size = 2**17
buff = ""
lines = 0

with open("hello_world.dat") as f:
    last_index = -1
    for line in f:
        index = int(line.split(':')[0].strip())
        val = line.split(':')[1].strip()[:-1]
        index_dif = index - last_index
        for _ in range(index_dif-1):
            lines += 4
            buff += "00000000\n"
            buff += "00000000\n"
            buff += "00000000\n"
            buff += "00000000\n"
        last_index = index
        v1 = val[6:8]
        v2 = val[4:6]
        v3 = val[2:4]
        v4 = val[0:2]
        for v in [v1, v2, v3, v4]:
            lines += 1
            buff += f"{bin(int(v,16))[2:].zfill(8)}\n"
    print(lines)
while lines != size:
    lines += 1
    buff += "00000000\n"
with open("res.dat", "w") as f:
    f.write(buff)