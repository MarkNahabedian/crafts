# Given an XML file of song lyrics (like JeopardyQuestions.xml), add
# <word> and <beat> elements to each <line>.

using ArgParse
using XML
using XML: Document, Comment, CData, Element

BEAT_SEPARATOR = "-"


function childn(node::Node, indices...)::Node
    if isempty(indices)
        node
    else
        childn(children(node)[indices[1]],
               indices[2:end]...)
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
    write(output_name, new_doc)
    println("Wrote $output_name.")
end

add_words_and_beats(node::Node) = 
    add_words_and_beats(node, Val(nodetype(node)))

add_words_and_beats(node::Node,
                    nodetype::Val{XML.Document}) =
                        Document(map(children(node)) do child
                                     add_words_and_beats(child)
                                 end)

add_words_and_beats(node::Node,
                    nodetype::Union{Val{XML.Comment},
                                    Val{XML.CData},
                                    Val{XML.Text}}) = node

add_words_and_beats(node::Node,
                    nodetype::Val{XML.Element}) =
    add_words_and_beats(node, nodetype, Val(Symbol(tag(node))))

add_words_and_beats(node::Node,
                    nodetype::Val{XML.Element},
                    tag::Union{Val{Symbol("song")},
                               Val{Symbol("verse")}}) =
    Element(tag,
            map(children(node)) do child
                add_words_and_beats(child)
            end...;
            attributes(node)...)

function add_words_and_beats(node::Node,
                             nodetype::Val{XML.Element},
                             tag::Val{Symbol("line")})
    # Get the text content and split into words (by whitespace) and
    # beats (by BEAT_SEPARATOR):
    Element(tag,
            map(children(node)) do child
                @assert child isa Node
                println(child)
                println(XML.Text)
                println(typeof(XML.Text))
                println(value(child))
                println(nodetype(child))
                if nodetype(child) == XML.Text
                    text_to_words_and_beats(value(child))
                elseif nodetype(child) in (XML.Comment, XML.CData)
                    child
                else
                    prinln("unsuppoted node in <line> context: $child")
                end
            end... ;
            attributes(node)...)
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

