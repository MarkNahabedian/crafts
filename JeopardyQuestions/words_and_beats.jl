# Given an XML file of song lyrics (like JeopardyQuestions.xml), add
# <word> and <beat> elements to each <line>.

using ArgParse
using XML
using XML: Document, Comment, CData, Element

BEAT_SEPARATOR = "-"

"""
    childn(node::Node, indices...)

Returns the child of node specified by the index.
if more than one index is specified then `childn`
recurses on the result and the remaining indices.
"""
function childn(node::Node, indices...)::Node
    if isempty(indices)
        node
    else
        childn(children(node)[indices[1]],
               indices[2:end]...)
    end
end


function safe_attributes(node::Node)
    a = attributes(node)
    if nodetype(node) == XML.Element
        if a == nothing
            []
        else
            a
        end
    else
        nothing
    end
end


function parse_command_line()
    cli = ArgParseSettings()
    @add_arg_table cli begin
        "filename"
        help = "The name of a song lyrics XML file to be processed."
        required = true
    end
    parse_args(cli)
end

function main()
    parsed = parse_command_line()
    add_words_and_beats(parsed["filename"])
end

# splitext

WORDS_AND_BEATS_SUFFIX = "-with-words-and-beats"

function add_words_and_beats(filename::AbstractString)
    basename, ext = splitext(filename)
    @assert ext == ".xml"
    new_doc = add_words_and_beats(read(filename, Node))
    output_name = "$basename$WORDS_AND_BEATS_SUFFIX$ext"
    XML.write(output_name, new_doc)
    println("Wrote $output_name.")
end

add_words_and_beats(node::Node) = 
    add_words_and_beats(node, Val(nodetype(node)))

add_words_and_beats(node::Node,
                    ::Val{XML.Document}) =
                        Document(map(children(node)) do child
                                     add_words_and_beats(child)
                                 end)

add_words_and_beats(node::Node,
                    nt::Union{Val{XML.Comment},
                                    Val{XML.CData},
                                    Val{XML.Text}}) = node

add_words_and_beats(node::Node,
                    nt::Val{XML.Element}) =
    add_words_and_beats(node, nt, Val(Symbol(tag(node))))

add_words_and_beats(node::Node,
                    ::Val{XML.Element},
                    tag::Union{Val{Symbol("song")},
                               Val{Symbol("verse")}}) =
    Element(tag,
            map(children(node)) do child
                add_words_and_beats(child)
            end...;
            safe_attributes(node)...)

function add_words_and_beats(node::Node,
                             ::Val{XML.Element},
                             tag::Val{Symbol("line")})
    # Get the text content and split into words (by whitespace) and
    # beats (by BEAT_SEPARATOR):
    new_children = []
    map(children(node)) do child
        @assert child isa Node
        if nodetype(child) == XML.Text
            push!(new_children,
                  text_to_words_and_beats(value(child))...)
        elseif nodetype(child) in (XML.Comment, XML.CData, XML.Element)
            push!(new_children, child)
        else
            println("unsuppoted node in <line> context: $child")
        end
    end
    Element(tag, new_children...;
            safe_attributes(node)...)
end

function text_to_words_and_beats(text::AbstractString)
    map(split(text)) do word
        Element("word",
                map(split(word, BEAT_SEPARATOR)) do beat
                    Element("beat", beat)
                end)
    end
end


main()
