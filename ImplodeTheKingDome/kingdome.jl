
using FileIO
using Base.Iterators: flatten

using MIDI
using MusicXML
using Mplay   # Pkg.add(url="https://github.com/JuliaMusic/Mplay.jl")
using MusicVisualizations

const TicksPerQuarterNote = 960

NoteVelocity = 0x50

# OpenTheKingdom::Notes = Notes(; tpq = TicksPerQuarterNote)

const WholeNote = 4 * TicksPerQuarterNote

struct Rest
    duration
end

# In score_element, duration is expressed as fraction of a whole note

score_element(n::Note)::Union{Note, Rest} = n

score_element(n::Number)::Union{Note, Rest} = Rest(n * WholeNote)

# Quarter note of named picth
score_element(n::String)::Union{Note, Rest} =
    Note(name_to_pitch(n), NoteVelocity, 0, WholeNote/4, 0)

function score_element(n::Tuple)::Union{Note, Rest}
    name, duration = n
    Note(name_to_pitch(name), NoteVelocity, 0, WholeNote * duration, 0)
end    


struct Measure
    number::Int
    notes::Vector{Note}

    Measure(number::Int, x...) =
        Measure(number, map(score_element, x)...)

    function Measure(number::Int, x::Union{Note, Rest}...)
        @assert(sum(n -> n.duration, x) == WholeNote,
                "Wrong beat count for measure $number")
        position = number * WholeNote
        notes = []
        for a in x
            if a isa Note
                push!(notes, translate(a, position))
            end
            position += a.duration
        end
        new(number, notes)
    end
end

Base.IteratorSize(::Type{Measure}) = Base.HasLength()
Base.IteratorEltype(::Type{Measure}) = Base.HasEltype()
Base.eltype(::Type{Measure}) = Note

Base.length(m::Measure) = length(m.notes)

Base.iterate(m::Measure) = Base.iterate(m, 1)

function Base.iterate(m::Measure, index::Int)
    if index >= 1 && index <= length(m.notes)
        return m.notes[index], index + 1
    end
    nothing
end

Base.isdone(m::Measure, index::Int) = index > length(m.notes)



# Middle C is MIDI note 60 = "C4"

Kingdom = [
    # https://notes-box.com/upload/iblock/171/aawn5gtpv87jc0l3ro09e151at1k51uv/Open_The_Kingdom_-_Philip_Glass.pdf
    # sheet 1:
    Measure(0, 1//4, ("D5", 3//16), ("D5", 1//16),"D5", "D5"),
    Measure(1, 1//4, ("C5", 3//16), ("C5", 1//16), ("C5", 1//2)),
    Measure(2, 1//8, ("Bb5", 1//8), ("Bb5", 1//8), ("Bb5", 1//8), ("Bb5", 1//2)),
    Measure(3, 1//8, ("A5", 1//8), ("A5", 1//8), ("A5", 1//8), ("G4", 1//2)),
    Measure(4, 1),
    Measure(5, 1),
    Measure(6, 1//8, ("Bb5", 1//8), ("Bb5", 1//8), ("Bb5", 1//8), ("Bb5", 1//2)),
    Measure(7, 1//8, ("A5", 1//8), ("A5", 1//8), ("A5", 1//8), ("G4", 1//2)),
    # sheet 2:
    # Open the kingdom:
    Measure(8, "F5", ("F5", 3//16), ("F5", 1//16), "F5", "F5"),
    Measure(9, 1//8, ("E5", 1//8), ("E5", 1//8), ("E5", 1//8), "E5", "E5"),
    Measure(10, 1//8, ("F5", 1//8), ("F5", 1//8), ("F5", 1//8), "F5", "F5"),
    Measure(11, "A6", ("A6", 3//16), ("A6", 1//16), "G5", "G5"),
    Measure(12, 1//8, ("F5", 1//8), ("F5", 1//8), ("F5", 1//8), "F5", "F5"),
    Measure(13, "E5", ("E5", 1//16), ("E5", 3//16), "E5", "E5"),
    Measure(14, "F5", ("F5", 3//16), ("F5", 1//16), "F5", "F5"),
    Measure(15, 1//8, ("A6", 1//8), ("A6", 1//8), ("A6", 1//8), "G5", "G5"),
    Measure(16, 1),
    # sheet 3
    Measure(17, 1),
    Measure(18, 1),
    Measure(19, 1),
    Measure(20, 1),
    Measure(21, 1),
    # Measures from here on have funny lengths
    Measure(22, ("F5", 3//8), ("F5", 1//8), "F5", 1//4),
    Measure(23, ("F5", 1)),
    Measure(24, ("F5", 1)),
    Measure(25, ("F5", 1)),
]

# musescore("kingdom_score.png", Notes(collect(flatten(Kingdom))))

save("kingdom.mid", Notes(collect(flatten(Kingdom))))

# mplay("kingdom.mid")
