.org 2
in R2        #R2 = 0CDAFE19
in R3        #R3=FFFF
in R4        #R4=F320
LDM R1,F5    #R1=F5
PUSH R1      #SP=7FC, M[7FE, 7FF] = F5
PUSH R2      #SP=7FA,M[7FC, 7FD]=0CDAFE19
POP R1       #SP=7FC,R1=0CDAFE19
POP R2       #SP=7FE,R2=F5
STD R2,200   #M[200, 201]=F5
STD R1,202   #M[202, 203]=0CDAFE19
LDD R3,202   #R3=0CDAFE19
LDD R4,200   #R4=5
END
