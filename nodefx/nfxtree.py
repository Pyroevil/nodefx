import bpy
from bpy.types import NodeTree, Node, NodeSocket
# Implementation of custom nodes from Python


# Derived from the NodeTree base type, similar to Menu, Operator, Panel, etc.
    
    
class NfxTree(NodeTree):
    # Description string
    '''A custom node tree type that will show up in the node editor header'''
    # Optional identifier string. If not explicitly defined, the python class name is used.
    bl_idname = 'NfxNodeTree'
    # Label for nice name display
    bl_label = 'Nfx Node Tree'
    # Icon identifier
    bl_icon = 'NODETREE'
    
    Nfx_upToDate = bpy.props.BoolProperty(default=1)
    #Nfx_outNodes = []


class NfxArraySocket(NodeSocket):
    # Description string
    '''Nfx Array socket type'''
    # Optional identifier string. If not explicitly defined, the python class name is used.
    bl_idname = 'NfxArraySocketType'
    # Label for nice name display
    bl_label = 'ArraySocket'
    
    # Optional function for drawing the socket input value
    def draw(self, context, layout, node, text):
        if self.is_output or self.is_linked:
            layout.label(text)
        else:
            layout.label(text)

    # Socket color
    def draw_color(self, context, node):
        return (1.0, 0.0,1.0, 1.0)


# Mix-in class for all custom nodes in this tree type.
# Defines a poll function to enable instantiation.
class NfxTreeNode:
    @classmethod
    def poll(cls, ntree):
        return ntree.bl_idname == 'NfxNodeTree'




def register():
    bpy.utils.register_class(NfxTree)
    bpy.utils.register_class(NfxArraySocket)


def unregister():

    bpy.utils.unregister_class(NfxTree)
    bpy.utils.unregister_class(NfxArraySocket)


if __name__ == "__main__":
    register()
