
# These are the stitch types we will document:

# 301 https://www.youtube.com/watch?v=zk9h8ByMcvg
# 401 https://www.youtube.com/watch?v=jEr_SNFMIqw
# 504 https://www.youtube.com/watch?v=KMrsT6jPR7s
# 605 https://www.youtube.com/watch?v=wH4mEIRzwOU

#=  Template:
SewingStitch(
    iso_number = 
    name = 
    number_of_threads = 
    confined_to_edge = 
    reidermeister_only =
    description = 
    paracord_hole_spacing = 
)
=#

SewingStitch(
    iso_number = 101,
    name = "Single Thread Chain Stitch",
    number_of_threads = 1,
    confined_to_edge = false,
    reidermeister_only = true,
    description = """

        A hook on the under side of the fabric is holding the loop
        from the previous stitch.  The threaded needle is above the
        fabric.  The needle passes into the fabric and through that
        under side loop and forms a new loop on the underside. The
        hook drops the previous loop and catches the new one.  The
        needle is retracted and the fabric advanced, pulling the
        stitch tight.

    """,
    paracord_hole_spacing = 0.5 * u"inch")

SewingStitch(
    iso_number = 209,
    name = "Straight or Running Stitch",
    number_of_threads = 1,
    confined_to_edge = false,
    reidermeister_only = false,
    description = """

        This is a common stitch used in hand sewing.  Start with a
        threaded needle above the fabric.  The needle is passed down
        through the fabric and the thread pulled tight.  Then the
        needle is passed back up through the fabric at the next
        location and the thread pulled tight.

""",
    paracord_hole_spacing = 0.5 * u"inch")

SewingStitch(
    # 301 https://www.youtube.com/watch?v=zk9h8ByMcvg
    iso_number = 301,
    name = "Lockstitch",
    number_of_threads = 2,
    confined_to_edge = false,
    reidermeister_only = false,
    description = """

    This is the fundamental stitch of machine sewing.  The top thread
    is threaded through a needle.  The bottom thread is wound around a
    floating bobbin.  The needle passes into the fabric.  As it is
    withdrawn the top thread forms a loop under the fabric.  a hook
    catches that loop and pulls it under and around the floating
    bobbin.  This has the effect of passing the bobbin thread through
    the loop in the top thread.  Once the needle is fully withdrawn
    and the top thread pulled taught, the crossing of the top and
    bottom threads is pulled into the fabric.

""",
    paracord_hole_spacing = 0.75 * u"inch")

SewingStitch(
    iso_number = 503,
    name = "Two Thread OverEdge (Serging)",
    number_of_threads = 2,
    confined_to_edge = true,
    reidermeister_only = true,
    description = md"""

    Interlocking loops are formed at the edge of the fabric.

    The top thread is threaded through a needle.  The edge thread is
    threaded through the lower looper.  The upper looper is not
    threaded but is instead fitted with a special hook called a
    converter.

    For the sake of exposition we start the description with the
    needle penetrating into the fabric.

    When the needle is at its lowest position and is rising upwards,
    its thread forms a loop.  The lower looper moves from left to
    right behind the needle, passing into and taking up the needle
    thread's loop.  Once the tip of the lower looper has entered the
    needle thread loop, the needle can continue its upward motion back
    through the fabric.

    When the lower looper reaches its rightmost position, the upper
    looper can move leftwards, hooking the lower looper thread and
    carrying it leftwards towards the needle.  The needle can then
    pass down through that loop in the lower thread on its next
    downward motion.  The upper looper can then move rightwards,
    releasing the lower looper's thread.

    """,
    paracord_hole_spacing = 1 * u"inch")

SewingStitch(
    # 504 https://www.youtube.com/watch?v=KMrsT6jPR7s
    iso_number = 504,
    name = "Three Thread OverEdge (Serging)",
    number_of_threads = 3,
    confined_to_edge = true,
    reidermeister_only = true,
    description = md"""

    This stitch uses one top needle and two loopers.  We start with
    the needle in its topmost position, the upper looper holding a
    loop of its thread across the top surface of the fabric under the
    needle, and the lower looper retracted at its point of motion
    that is furthest from the edge of the fabric.

    - The upper needle passes a loop of the needle thread through the
      top loop and the fabric.

    - The lower loopper moves towards the edge while passing a loop
      of its thread through the needle thread loop under the fabric.
      Meanwhile, the upper looper moves to the edge of the fabric.

    - Next the lower looper pulls a loop of its thread to the edge of
      the fabric.

    - Finally, the upper looper passes a loop of its thread through
      that loop of the lower looper's thread and returns to its starting
      position.

    """,
    paracord_hole_spacing = 1.5 * u"inch"
)
