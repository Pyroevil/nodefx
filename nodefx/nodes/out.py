import bpy
from bpy.types import NodeTree, Node, NodeSocket
from nodefx.nfxtree import NfxTreeNode

class NfxOutNode(Node, NfxTreeNode):
    '''Output node to process tree data'''
    bl_idname = 'NfxOutNode'
    bl_label = 'Out'
    bl_icon = 'SOUND'
    
    Nfx_Value = bpy.props.IntProperty(default=1)
    Nfx_resetFrame = bpy.props.IntProperty(default=0)
    Nfx_updatedFrame = bpy.props.IntProperty(default=0)
    
    def init(self, context):
        self.inputs.new('NfxArraySocketType', "data")
        self.addToTree()
        
    def copy(self, node):
        self.addToTree()
        pass

    def free(self):
        self.delTotree()
        pass

    def draw_buttons(self, context, layout):
        layout.prop(self, "Nfx_resetFrame","Init Frame:")
        pass
        
    def draw_buttons_ext(self, context, layout):
        pass

    def draw_label(self):
        return "Out"
        
    def addToTree(self):
        if "Nfx_outNodes" not in self.id_data:
            self.id_data['Nfx_outNodes'] = [self.name]
            print('CREATED')
        else:
            # don't know why but append() don't work. Here is the working alternative to it.
            self.id_data['Nfx_outNodes'] += [self.name]
            print('ADDED')
        pass
        
    def delTotree(self):
        if self.name in self.id_data['Nfx_outNodes']:
            i = self.id_data['Nfx_outNodes'].index(self.name)
            self.id_data['Nfx_outNodes'] = self.id_data['Nfx_outNodes'][:i] + self.id_data['Nfx_outNodes'][i+1:]
            print('DELETED',i)
        print('CALL')
    

import nodeitems_utils
from nodeitems_utils import NodeCategory, NodeItem, NodeItemCustom
                  

class NfxNodeCategory(NodeCategory):
    @classmethod
    def poll(cls, context):
        return context.space_data.tree_type == 'NfxNodeTree'
    
cat = NfxNodeCategory("OUT", "Out", items=[NodeItem("NfxOutNode"),])

node_categories = [cat]


def register():
    bpy.utils.register_class(NfxOutNode)
    nodeitems_utils.register_node_categories("NFX_NODES", node_categories)


def unregister():
    nodeitems_utils.unregister_node_categories("NFX_NODES")

    bpy.utils.unregister_class(NfxOutNode)


if __name__ == "__main__":
    register()
