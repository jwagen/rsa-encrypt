def getBit(a, n):
    """Get the nth bit from a"""
    if (a & (1<<n)):
        return 1
    else:
        return 0

def monpro(a, b, n, k = 128):
    """Calculates the montgomery product av a and b
    a*b*r**-1 mod n"""
    assert n%2 != 0, 'n must be a odd number'
    if k == None:    
        k = len(bin(max(a,b)))
    u = 0
    print(k)

    for i in range(0, k):
        if getBit(a, i):
            u = u + b

        if getBit(u,0): #Test if u is odd
            u = u + n
        u = u >> 1

    if u >= n: # Subtracts if u is equal or larger to n, as u mod n should be between 0 and n-1 
        u = u - n

    return u

def monexp(M, e, n):
    """Calculates M**e mod n using montgomery exponentation"""
    assert n%2 != 0, 'n must be a odd number'

    k = 128
    r = 2**k
    r_2 = r**2 % n

    # Convert to montgomery form
    M_ = monpro(M, r_2, n)
    x_ = monpro(1, r_2, n)
    print("M_ = ", M_)
    print("x_ = ", x_)


    for i in range(k-1, -1, -1): #Loop from msb to lsp
        x_ = monpro(x_, x_, n)
        if getBit(e, i):
            x_ = monpro(M_, x_, n)


    # Convert from montgomery form to normal
    x = monpro(x_, 1, n)
    return x



def testmonpro(a,b,n):
    k = 128
    r = 2**k
    r_2 = r**2 % n

    #a_ = monpro(a, r_2, n)
    #b_ = monpro(b, r_2, n)
    a_ = a * r % n

    #x_ = monpro(a_, b_, n) #Square

    #x = monpro(1, x_, n)
    x = monpro(a_, b, n)
    print('X = ', x, )
    return x

