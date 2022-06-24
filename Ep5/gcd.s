ldur    x0, [xzr. #0]
ldur    x1, [xzr, #8]
ldur    x2, [xzr, #16]
sub     x3, x2, x1
cbz     x3, #7
and     x3, x3, x0
cbz     x3, #3  
sub     x1, x1, x2
b       #-5
sub     x2, x2, x1
b       #-7
stur    x1, [xzr, #0]