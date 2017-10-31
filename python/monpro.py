from __future__ import print_function 
import click
import random

def getBit(a, n):
    """Get the nth bit from a"""
    if (a & (1<<n)):
        return 1
    else:
        return 0

def monpro(a, b, n, k = 128, debug=False):
    """Calculates the montgomery product av a and b
    a*b*r**-1 mod n"""
    assert n%2 != 0, 'n must be a odd number'
    if k == None:    
        k = len(bin(max(a,b)))
    u = 0
    print(debug)

    for i in range(0, k):
        if getBit(a, i):
            u = u + b

        if getBit(u,0): #Test if u is odd
            u = u + n
        u = u >> 1
        if(debug):
            print(hex(u))

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
    #print("M_ = ", M_)
    #print("x_ = ", x_)


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

def hex_to_int(a):
    if a != None:
        a = int(str(a), 16)

    return a

def str_to_int(a):
    if a != None:
        a = int(a)

    return a

@click.command()
@click.option('-m', type=(int), help='Message to be encrypted.')
@click.option('--public-key', type=int, help='Public exponent.')
@click.option('--private-key', type=int, help='Private exponent.')
@click.option('-n', type=(str), help='Modulo number.')
@click.option('-k', type=(str), default=128, help='Number of bits to use.')
@click.option('-a', type=(str), help='Multiplier for monpro.')
@click.option('-b', type=(str), help='Multiplier for monpro.')
@click.option('--encrypt', is_flag=True, help='Encrypt the message.')
@click.option('--decrypt', is_flag=True, help='Decrypt the message.')
@click.option('--monpro', is_flag=True, help='Calculate the montgomery product of a * b r**-1 mod n.')
@click.option('-x', is_flag=True, help='Output data as hex')
@click.option('-r', is_flag=True, help='Outputs the values for r mod n and r**2 mod n')
@click.option('--debug', is_flag=True, help='Output data as hex')
@click.option('--loop', type=int, help='Loop through and generate random input data.')
def cli(m, public_key, private_key, n, k, a, b, encrypt, decrypt, monpro, x, r, debug, loop):
    """
    Command line interface for montgomery exponentiation.
    
    Examples:
    Loopback with both --encrypt and --decrypt enabled
    monpro.py --encrypt --decrypt -m 12312311 --public-key 65537 --private-key 123393368995652170316939386126073244113 -n 196525583218743014100704959829497557023
    Encrypted  12312311 , encrypted value  139608985220169980430515913107853261509 , decrypted value  12312311
    """
    if x:
        a = hex_to_int(a)
        b = hex_to_int(b)
        n = hex_to_int(n)
        k = hex_to_int(k)
        m = hex_to_int(m)
        public_key = hex_to_int(public_key)
        private_key = hex_to_int(private_key)
    else:
        a = str_to_int(a)
        b = str_to_int(b)
        n = str_to_int(n)
        k = str_to_int(k)
        m = str_to_int(m)
        public_key = str_to_int(public_key)
        private_key = str_to_int(private_key)


    if loop:
        for i in range(1, loop):
            a = random.randrange(2**k)
            b = random.randrange(2**k)
            n = random.randrange(1,2**k, 2)

            awnser = 0
            if encrypt:
                awnser = monexp(a, b, n)


            elif decrypt:
                awnser = monexp(a, b, n)

            elif monpro:
                awnser = globals()['monpro'](a, b, n, debug=debug)

            else :
                print('Please select what operation to do')
                return

            if x:

                print("{1:0{0}X} {2:0{0}X} {3:0{0}X} {4:0{0}X}".format(32, a, b, n, awnser))

            else:
                print(a, ' ', b, ' ', n, ' ', awnser)





    else:
        if encrypt and decrypt:
            encrypted_message = monexp(m, public_key, n)
            decrypted = monexp(encrypted_message, private_key, n)
            
            print("Encrypted ", m, ", encrypted value ", encrypted_message,", decrypted value ", decrypted)
            return
        
        elif encrypt:
            encrypted_message = monexp(m, public_key, n)
            print("Encrypted ", m, ", encrypted value ", encrypted_message)


        elif decrypt:
            decrypted = monexp(m, private_key, n)
            print(", encrypted value ", m, ", decrypted value ", decrypted)

        elif monpro:
            awnser = globals()['monpro'](a, b, n, debug=debug)

            if x:
                print("{1:0{0}X} {2:0{0}X} {3:0{0}X} {4:0{0}X}".format(32, a, b, n, awnser))
            else:
                print(awnser)
            print(globals()['monpro'](a, b, n, debug=debug))

        if r:
            print("{1:0{0}X} {2:0{0}X}".format(32, 2**k % n, 2**(k*2) % n))






if __name__ == '__main__':
    cli()
