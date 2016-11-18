#cython: profile=False
#cython: boundscheck=False
#cython: cdivision=True

cimport cython
from time import clock
from libc.math cimport sin , ceil , floor , fabs
from cython.parallel import parallel , prange , threadid
from libc.stdlib cimport malloc , realloc, free , rand , srand
from libc.stdio cimport printf, sprintf
from libc.string cimport strcmp, strlen , strcpy

cdef extern from "string.h":
    int strcmp(char* str1,char* str2)

cdef World *world = <World *>malloc(1 * cython.sizeof(World))
world.trees = NULL
world.treesize = 0


cpdef build(dict):
    global world
    cdef int i = 0
    cdef int ii = 0
    cdef int l = 0
    cdef int trid = 0
    cdef int brid = 0
    cdef int pylinksize = 0
    cdef int innode = 0
    cdef int outnode = 0
    cdef int socketin = 0
    cdef int socketout = 0
    cdef char *treename = <char *>malloc( len(dict["TreeName"]) * cython.sizeof(char) )
    cdef char *branchname = <char *>malloc( len(dict["BranchName"]) * cython.sizeof(char) )
    strcpy(treename,dict["TreeName"].encode())
    strcpy(branchname,dict["BranchName"].encode())
    cdef Tree *tree = NULL
    cdef Branch *branch = NULL
    cdef Node *nodes = NULL
    
    trid = addtree(treename,true)
    brid = addbranch(branchname,trid,true)
    #print("TEST1",world.trees[0].name,world.trees[0].branchs[0].name,trid,brid)
    tree = &world.trees[trid]
    branch = &tree.branchs[brid]
    pynodes =  dict["Nodes"]
    pylinks = dict["Links"]
    pylinksize = len(pylinks)
    branch.nodesize = len(pynodes)
    branch.nodes = <Node *>malloc( branch.nodesize * cython.sizeof(Node) )
    nodes = tree.branchs.nodes
    
    for i in range(branch.nodesize):
        branch.nodes[i] = nodes[i]
        nodes[i].id = i
        nodes[i].branch = branch
        nodes[i].inputs = NULL
        nodes[i].insize = 0
        nodes[i].outputs = NULL
        nodes[i].outsize = 0
        nodes[i].data = NULL
        nodes[i].depth = 0
        nodes[i].runs = 0
        nodes[i].maxruns = 0
        if pynodes[i]["type"] == "process":
            nodes[i].type = n_process
            nodes[i].func = &processFnc
            nodes[i].insize = 1
            nodes[i].inputs = <Node **>malloc( nodes[i].insize * cython.sizeof(Node) )
            branch.root = &nodes[i]
            print(" Node",pynodes[i]["type"]," added.")
            continue
        elif pynodes[i]["type"] == "float":
            nodes[i].type = n_float
            nodes[i].func = &floatFnc
            nodes[i].data = <Data *>malloc( 1 * cython.sizeof(Data) )
            nodes[i].data.type = t_float
            nodes[i].data.value = <DataPtr *>malloc( 1 * cython.sizeof(DataPtr) )
            nodes[i].data.value.f = <float *>malloc( 1 * cython.sizeof(float) )
            nodes[i].data.value.f[0] = pynodes[i]["value"]
            print(" Node",pynodes[i]["type"],"with value",nodes[i].data.value.f[0]," added.")
            continue
        elif pynodes[i]["type"] == "add":
            nodes[i].type = n_add
            nodes[i].func = &addFnc
            nodes[i].insize = 2
            nodes[i].inputs = <Node **>malloc( nodes[i].insize * cython.sizeof(Node) )
            nodes[i].data = <Data *>malloc( 1 * cython.sizeof(Data) )
            nodes[i].data.value = <DataPtr *>malloc( 1 * cython.sizeof(DataPtr) )
            nodes[i].data.value.ar = <Array *>malloc( 1 * cython.sizeof(Array) )
            nodes[i].data.value.ar.array = <DataPtr *>malloc( 1 * cython.sizeof(DataPtr) )
            print(" Node",pynodes[i]["type"]," added.")
            continue
        elif pynodes[i]["type"] == "buildarray":
            nodes[i].type = n_buildarray
            nodes[i].func = &buildarray
            nodes[i].insize = 2
            nodes[i].inputs = <Node **>malloc( nodes[i].insize * cython.sizeof(Node) )
            nodes[i].data = <Data *>malloc( 1 * cython.sizeof(Data) )
            nodes[i].data.value = <DataPtr *>malloc( 1 * cython.sizeof(DataPtr) )
            nodes[i].data.value.ar = <Array *>malloc( 1 * cython.sizeof(Array) )
            nodes[i].data.value.ar.array = <DataPtr *>malloc( 1 * cython.sizeof(DataPtr) )
            nodes[i].data.value.ar.size = 0
            print(" Node",pynodes[i]["type"]," added.")
            continue
        
    for i in range(pylinksize):
        innode = pylinks[i][0][0]
        outnode = pylinks[i][1][0]
        socketin = pylinks[i][0][1]
        socketout = pylinks[i][1][1]
        nodes[outnode].inputs[socketout] = &nodes[innode]
        nodes[innode].maxruns += 1
        #print("Link id:",i," ",nodes[innode].id,"(",socketin,")","->",nodes[outnode].id,"(",socketout,")")
        

cpdef process(dict):
    global world
    cdef int i = 0
    cdef int trid = 0
    cdef int brid = 0
    cdef char *treename = <char *>malloc( len(dict["TreeName"]) * cython.sizeof(char) )
    cdef char *branchname = <char *>malloc( len(dict["BranchName"]) * cython.sizeof(char) )
    strcpy(treename,dict["TreeName"].encode())
    strcpy(branchname,dict["BranchName"].encode())
    cdef Tree *tree = NULL
    cdef Branch *branch = NULL
    cdef Node *nodes = NULL
    
    trid = addtree(treename,false)
    brid = addbranch(branchname,trid,false)
    tree = &world.trees[trid]
    branch = &tree.branchs[brid]
    #print("TEST2",world.trees[0].name,world.trees[0].branchs[0].name,trid,brid)
    #print(branch.nodes[2].data.value.f[0])
    #print(branch.nodes[3].data.value.f[0])
    branch.root[0].data = branch.root.func(&branch.root[0],0,0)
    printf("value: %f type %i \n",branch.root[0].data.value.f[0],branch.root[0].data.type)

    
cdef int addtree(char *name, bool create):
    global world
    cdef int i
    for i in range(world.treesize):
        if strcmp(world.trees[i].name,name) == 0:
            free(name)
            return i
    if create == true:
        world.trees = <Tree *>realloc(world.trees,(world.treesize + 1) * cython.sizeof(Tree))
        i = world.treesize
        world.trees[i].id = world.treesize
        world.trees[i].name = name
        world.trees[i].branchs = NULL
        world.trees[i].branchsize = 0
        world.treesize += 1
        #print("Tree index",i," created with name",world.trees[i].name)
        return world.treesize - 1
    return -1
   
   
cdef int addbranch(char *name,int trid, bool create):
    global world
    cdef int i
    for i in range(world.trees[trid].branchsize):
        if strcmp(world.trees[trid].branchs[i].name,name) == 0:
            free(name)
            return i
    if create == true:
        world.trees[trid].branchs = <Branch *>realloc(world.trees[trid].branchs,(world.treesize + 1) * cython.sizeof(Branch))
        i = world.trees[trid].branchsize
        world.trees[trid].branchs[i].name = name
        world.trees[trid].branchs[i].tree = &world.trees[trid]
        world.trees[trid].branchs[i].id = world.trees[trid].branchsize
        world.trees[trid].branchs[i].root = NULL
        world.trees[trid].branchs[i].nodes = NULL
        world.trees[trid].branchs[i].nodesize = 0
        world.trees[trid].branchs[i].save = NULL
        world.trees[trid].branchs[i].savesize = 0
        world.trees[trid].branchsize += 1
        #print("Branch index",world.trees[trid].branchsize - 1," from Tree ",trid," created with name",world.trees[trid].branchs[i].name)
        return world.trees[trid].branchsize - 1
    return -1
    
    
cpdef testing():
    cdef int i = 0
    cdef int ii = 0
    cdef int a = 6
    cdef float b = 6.6
    cdef char *c = "devil"
    cdef Array d
    cdef int[4] e = [6,7,8,9]
    d.size = 4
    d.memsize = d.size
    print(d.size,d.memsize)
    d.array = <DataPtr *>malloc(d.memsize * cython.sizeof(DataPtr))
    d.array.i = <int *>malloc(d.memsize * cython.sizeof(int))
    for i in range(d.size):
        d.array.i[i] = e[i]
    cdef Struct test
    test.paramsize = 4
    test.parammem = test.paramsize
    test.param = <DataPtr *>malloc(test.parammem * cython.sizeof(DataPtr))
    test.partype = <DataType *>malloc(test.parammem * cython.sizeof(DataType))
    test.partype[0] = t_int
    test.partype[1] = t_float
    test.partype[2] = t_char
    test.partype[3] = t_arrint
    test.param[0].i = &a
    test.param[1].f = &b
    test.param[2].c = &c
    test.param[3].ar = &d
    
    for i in range(test.paramsize):
        if test.partype[i] == t_int:
            print('Parameter:',i,'Int:',test.param[i].i[0])
        if test.partype[i] == t_float:
            print('Parameter:',i,'Float:',test.param[i].f[0])
        if test.partype[i] == t_char:
            print('Parameter:',i,'Char:',test.param[i].c[0])
        if test.partype[i] == t_arrint:
            print('Parameter:',i,'arrInt of size:',test.param[i].ar[0].size)
            for ii in range(test.param[i].ar.size):
                print('   index',ii,'Int:',test.param[i].ar.array.i[ii])

                
cdef Data* processFnc(Node *nodeA,int depth, int count):
    global world
    #print("Calculate",nodeA.id)
    cdef Data *input = NULL
    input = nodeA.inputs[0][0].func(&nodeA.inputs[0][0],depth,count)
    return input
    
    
cdef Data* addFnc(Node *nodeA,int depth, int count):
    global world
    #print("Calculate",nodeA.id)
    cdef Data *input1 = NULL
    cdef Data *input2 = NULL
    cdef Data *output = <Data *>malloc( 1 * cython.sizeof(Data) )
    output.value = <DataPtr *>malloc( 1 * cython.sizeof(DataPtr) )
    #print("add nodes:",nodeA.inputs[0][0].id,nodeA.inputs[0][1].id)
    
    output.value.f = <float *>malloc( 1 * cython.sizeof(float) )
    input1 = nodeA.inputs[0][0].func(&nodeA.inputs[0][0],depth,count)
    input2 = nodeA.inputs[0][1].func(&nodeA.inputs[0][1],depth,count)
    output.type = input2.type
    output.value.f[0] = input1.value.f[0] + input2.value.f[0]
    free(input1)
    free(input2)
    return output
    

cdef Data* floatFnc(Node *nodeA,int depth, int count):
    global world
    cdef Data *output = <Data *>malloc( 1 * cython.sizeof(Data) )
    output.type = t_float
    output.value = <DataPtr *>malloc( 1 * cython.sizeof(DataPtr) )
    output.value.f = <float *>malloc( 1 * cython.sizeof(float) )
    output.value.f[0] = nodeA.data.value.f[0]
    #print("Calculate",nodeA.id,output.type)
    return output
    
    
cdef Data* buildarray(Node *nodeA,int depth, int count):
    global world
    cdef int l = 0
    #print("Calculate",nodeA.id)
    cdef Data *input1 = NULL
    cdef Data *input2 = NULL
    #print("add nodes:",nodeA.inputs[0][0].id,nodeA.inputs[0][1].id)
    input2 = nodeA.inputs[0][1].func(&nodeA.inputs[0][1],depth,count)
    nodeA.data.value.ar.type = nodeA.inputs[0][0].data.type
    l = <int>input2.value.f[0]
    nodeA.data.value.ar.array.f = <float *>malloc( l * cython.sizeof(float) )
    for i in range(l):
        input1 = nodeA.inputs[0][0].func(&nodeA.inputs[0][0],depth,count)
        nodeA.data.value.ar.array.f[i] = input1.value.f[0]
    return nodeA.data


cdef struct World:
    Tree * trees
    int treesize
    
    
cdef struct Tree:
    int id
    char *name
    Branch *branchs
    int branchsize
    

cdef struct Branch:
    int id
    Tree *tree
    char *name
    Node *root
    Node *nodes
    int nodesize
    Save *save
    int savesize
    
    
cdef struct Node:
    int id
    NodeType type
    Branch *branch
    Node **inputs
    int insize
    Node *outputs
    int outsize
    Data *data
    Data *(*func)(Node*,int, int)
    int depth
    int runs
    int maxruns
    

cdef struct Struct:
    int id
    char *name
    DataType *partype
    DataPtr *param
    char **parmname
    int paramsize
    int parammem
   
   
cdef struct Save:
    int id
    char *name
    DataType type
    DataPtr *data
    
cdef struct Data:
    int id
    DataType type
    DataPtr *value
    
    
cdef struct Array:
    int id
    DataType type
    DataPtr *array
    int size
    int memsize

    
cdef union DataPtr:
    int *i
    float *f
    char **c
    Struct *s
    Array *ar
    
   
cdef enum DataType:
    t_int,t_float,t_char,t_struct,t_arrint,t_arrfloat,t_arrchar,t_arrstruct

    
cdef enum bool:
    false, true
    
    
cdef enum NodeType:
    n_process,n_float,n_add,n_buildarray
