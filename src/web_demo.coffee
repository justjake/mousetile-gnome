
# ancient file from the webkit prototype
# TODO: (distant future): port app.coffee to the web

####
# Entry point
####

#= require "util"
#= require "rect"
#= require "region"

window.onload = ->

    GOLDEN = 1.62

    H = 600
    W = H * GOLDEN


    window.C = C = Region


    select_random = ->
        return Math.random() < 0.5

    select_alternate = (initial) ->
        prev = ! initial
        return ->
            prev = ! prev
            return prev

    select_alternate_actual = select_alternate(true)

    super_tree = (cur_depth) ->
        # all params in source
        # duur
        MAX_DEPTH    = 4
        MAX_CHILDREN = 3
        CHILD_CHANCE = 1
        SUBTREE_CHANCE = 1

        DIRECTION = select_random

        # base case
        if cur_depth > MAX_DEPTH
            return new Container(500, 500)

        root = new Container(W, H, DIRECTION())
        while (Math.random() < CHILD_CHANCE) and root.children.length <= MAX_CHILDREN
            if Math.random() < CHILD_CHANCE
                child = super_tree(cur_depth + 1)
            else
                child = new Container(500, 500)
            root.addChild(child)

        return root


    
    create_tree = (dir_selector, count) ->
        # base case: return a plain container
        if count == 0
            return new C(400, 400)

        # reverse the direction
        root = new C(W, H, dir_selector())

        empty_child = new C(400, 400)

        # sub-tree
        full_child = create_tree(dir_selector, count - 1)

        # add children
        root.addLast(empty_child)
        root.addLast(full_child)

        return root

    window.layout_tree = layout_tree = (container) ->
        container.layout()
        if container.managed_windows.length
            for c in container.managed_windows
                layout_tree(c)

    window.root = root =  create_tree(select_alternate(true), 15)
    root.layoutRecursive(true)
    Util.Log(root)

    # break abstractions
    document.body.appendChild(root.native)


