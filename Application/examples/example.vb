Sub Main()
On Error GoTo Failed


	Dim app As Netica.Application
	app = New Netica.Application

	Dim casefile As Streamer
	Dim net As Bnet
	Set netfile = app.NewStream("C:\Netica Data\BNs\Car_Diagnosis_0_Learned.dne")
	Set casefile = app.NewStream("C:\Netica Data\Cases\Good Cases\Car Cases 10.cas")
	
	Set net = app.ReadBNet(netfile)
	net.AutoUpdate = 1
	net.Compile

	Dim lights_node As Bnode
	Set lights_node = net.Node("Lights")

	Dim lights_dim As Long
	lights_dim = lights_node.GetStateIndex("dim")

	Dim id As Long
	Dim fr As Double
	Dim caseposn As Long

	Dim done As Boolean
	done = False

	caseposn = FirstCase

	Do
		net.RetractFindings
		net.ReadFindings case_posn:=caseposn, stream:=casefile, IDNum:=id, freq:=fr
		net.ReadFindings case_posn:=caseposn, stream:=casefile, nodes:=net.Nodes, IDNum:=id, freq:=fr

		If caseposn = NoMoreCases Then
			done = True
		Else
			MsgBox "Belief in Lights dim = " & lights_node.GetBelief(lights_dim)
		End If
		
		caseposn = NextCase
	Loop Until done

	net.Delete

	Exit Sub
	
Failed:

	MsgBox "Error " & ((err.Number And &H7FFF) - 10000) & ": " & err.Description

End Sub
