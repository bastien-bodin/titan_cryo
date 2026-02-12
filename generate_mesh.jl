using Printf

# domain parameters

L_x = 100.0 # total length /x (m)
L_y = 100.0 # total length /y (m)
L_z = 50.0  # total height /z (m)

# Vent parameters
C_x = 50.0 # center of the vent /x (m)
C_y = 50.0 # center of the vent /y (m)
W_vent = 10.0 # Vent width (square for now) (m)

# Resolution (nbr of cells)
N_vent = 20 # cells along the vent
N_side = 40 #cells along ground
N_z = 30 # cells in height
Grad_z = 1.0 # vert. grading

# compute coords
# We consider 3 zones in X and 3 zones in Y
# X0 --- X1 --- X2 --- X3
# Y0 --- Y1 --- Y2 --- Y3

x_coords = [0.0, C_x - W_vent/2, C_x + W_vent/2, L_x]
y_coords = [0.0, C_y - W_vent/2, C_y + W_vent/2, L_y]
z_coords = [0.0, L_z]

# Generate file
filename = "system/blockMeshDict"
open(filename, "w") do f
    #header openFOAM
    write(f, """
/*----------------*- C++ -*----------------*/
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    object      blockMeshDict;
}
// * * * * * * * * * * * * * * * * * * * //

convertToMeters 1;

vertices
(
""")
    # writing vertices
    v_idx = 0
    for k in 1:2 #z levels
        z = z_coords[k]
        for j in 1:4
            y = y_coords[j]
            for i in 1:4
                x = x_coords[i]
                @printf(f, "(%.2f %.2f %.2f) // %d\n", x, y, z, v_idx)
                v_idx += 1
            end
        end
    end

    write(f, "\n);\n\nblocks\n(\n")

    #writing blocks

    idx(i, j, k) = (k-1)*16 + (j-1)*4 + (i-1)
    for j in 1:3
        for i in 1:3
            p0 = idx(i,   j,   1)
            p1 = idx(i+1, j,   1)
            p2 = idx(i+1, j+1, 1)
            p3 = idx(i,   j+1, 1)
            p4 = idx(i,   j,   2)
            p5 = idx(i+1, j,   2)
            p6 = idx(i+1, j+1, 2)
            p7 = idx(i,   j+1, 2)

            # Choix de la résolution
            nx = (i == 2) ? N_vent : N_side
            ny = (j == 2) ? N_vent : N_side
            
            @printf(f, "    hex (%d %d %d %d %d %d %d %d) (%d %d %d) simpleGrading (1 1 %f)\n", 
                    p0, p1, p2, p3, p4, p5, p6, p7, nx, ny, N_z, Grad_z)
        end
    end

    write(f, ");\n\nedges\n();\n\nboundary\n(\n")

    # writing BC

    # Inlet
    write(f, "    inlet\n    {\n        type patch;\n        faces\n        (\n")
    p0 = idx(2, 2, 1); p1 = idx(3, 2, 1); p2 = idx(3, 3, 1); p3 = idx(2, 3, 1)
    @printf(f, "            (%d %d %d %d)\n", p0, p3, p2, p1)
    write(f, "        );\n    }\n")

    # Ground
    write(f, "    ground\n    {\n        type wall;\n        faces\n        (\n")
    for j in 1:3
        for i in 1:3
            if (i == 2 && j == 2) continue end # we skip the vent
            p0 = idx(i, j, 1); p1 = idx(i+1, j, 1); p2 = idx(i+1, j+1, 1); p3 = idx(i, j+1, 1)
            @printf(f, "            (%d %d %d %d)\n", p0, p3, p2, p1)
        end
    end
    write(f, "        );\n    }\n")

    # 3. Atmosphere
    write(f, "    atmosphere\n    {\n        type patch;\n        faces\n        (\n")
    for j in 1:3
        for i in 1:3
            p4 = idx(i, j, 2); p5 = idx(i+1, j, 2); p6 = idx(i+1, j+1, 2); p7 = idx(i, j+1, 2)
            @printf(f, "            (%d %d %d %d)\n", p4, p5, p6, p7)
        end
    end
    write(f, "        );\n    }\n")

    # 4. Walls
    write(f, "    walls\n    {\n        type wall;\n        faces\n        (\n")
    for i in 1:3 
        p0=idx(i,1,1); p1=idx(i+1,1,1); p5=idx(i+1,1,2); p4=idx(i,1,2)
        @printf(f, "            (%d %d %d %d)\n", p0, p1, p5, p4)
    end
    for i in 1:3
        p3=idx(i,4,1); p2=idx(i+1,4,1); p6=idx(i+1,4,2); p7=idx(i,4,2)
        @printf(f, "            (%d %d %d %d)\n", p3, p7, p6, p2) # Attention orientation
    end
    for j in 1:3
        p0=idx(1,j,1); p3=idx(1,j+1,1); p7=idx(1,j+1,2); p4=idx(1,j,2)
        @printf(f, "            (%d %d %d %d)\n", p0, p4, p7, p3)
    end
    for j in 1:3
        p1=idx(4,j,1); p2=idx(4,j+1,1); p6=idx(4,j+1,2); p5=idx(4,j,2)
        @printf(f, "            (%d %d %d %d)\n", p1, p2, p6, p5)
    end

    write(f, "        );\n    }\n);\n\nmergePatchPairs\n(\n);\n")

end

println("--> system/blockMeshDict made successfully !")