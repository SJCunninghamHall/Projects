namespace FindInFiles
{
    partial class frmFiF
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle2 = new System.Windows.Forms.DataGridViewCellStyle();
            this.txtFilePattern = new System.Windows.Forms.TextBox();
            this.txtDirectoryPattern = new System.Windows.Forms.TextBox();
            this.btnDirSel = new System.Windows.Forms.Button();
            this.btnFind = new System.Windows.Forms.Button();
            this.lblCTECount = new System.Windows.Forms.Label();
            this.lblCTEsFound = new System.Windows.Forms.Label();
            this.txtSearched = new System.Windows.Forms.TextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.txtDirPattern = new System.Windows.Forms.TextBox();
            this.label2 = new System.Windows.Forms.Label();
            this.label3 = new System.Windows.Forms.Label();
            this.label4 = new System.Windows.Forms.Label();
            this.dgvResults = new System.Windows.Forms.DataGridView();
            this.btnClear = new System.Windows.Forms.Button();
            this.txtWriteTo = new System.Windows.Forms.TextBox();
            this.label5 = new System.Windows.Forms.Label();
            this.btnWriteTo = new System.Windows.Forms.Button();
            this.chkWrite = new System.Windows.Forms.CheckBox();
            this.dgvHits = new System.Windows.Forms.DataGridView();
            this.label6 = new System.Windows.Forms.Label();
            this.label7 = new System.Windows.Forms.Label();
            this.label8 = new System.Windows.Forms.Label();
            this.lblItemCountTotal = new System.Windows.Forms.Label();
            this.cmbRegEx = new System.Windows.Forms.ComboBox();
            this.lblProgess = new System.Windows.Forms.Label();
            ((System.ComponentModel.ISupportInitialize)(this.dgvResults)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.dgvHits)).BeginInit();
            this.SuspendLayout();
            // 
            // txtFilePattern
            // 
            this.txtFilePattern.Location = new System.Drawing.Point(439, 41);
            this.txtFilePattern.Name = "txtFilePattern";
            this.txtFilePattern.Size = new System.Drawing.Size(249, 20);
            this.txtFilePattern.TabIndex = 0;
            this.txtFilePattern.Text = "*.sql";
            // 
            // txtDirectoryPattern
            // 
            this.txtDirectoryPattern.Location = new System.Drawing.Point(75, 67);
            this.txtDirectoryPattern.Name = "txtDirectoryPattern";
            this.txtDirectoryPattern.Size = new System.Drawing.Size(613, 20);
            this.txtDirectoryPattern.TabIndex = 1;
            this.txtDirectoryPattern.Text = "C:\\TFS-New\\Cross Client\\ICE";
            // 
            // btnDirSel
            // 
            this.btnDirSel.Location = new System.Drawing.Point(694, 65);
            this.btnDirSel.Name = "btnDirSel";
            this.btnDirSel.Size = new System.Drawing.Size(25, 23);
            this.btnDirSel.TabIndex = 3;
            this.btnDirSel.Text = "...";
            this.btnDirSel.UseVisualStyleBackColor = true;
            this.btnDirSel.Click += new System.EventHandler(this.btnDirSel_Click);
            // 
            // btnFind
            // 
            this.btnFind.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.btnFind.Location = new System.Drawing.Point(1083, 601);
            this.btnFind.Name = "btnFind";
            this.btnFind.Size = new System.Drawing.Size(75, 23);
            this.btnFind.TabIndex = 4;
            this.btnFind.Text = "&Find";
            this.btnFind.UseVisualStyleBackColor = true;
            this.btnFind.Click += new System.EventHandler(this.btnFind_Click);
            // 
            // lblCTECount
            // 
            this.lblCTECount.AutoSize = true;
            this.lblCTECount.Location = new System.Drawing.Point(1111, 46);
            this.lblCTECount.Name = "lblCTECount";
            this.lblCTECount.Size = new System.Drawing.Size(13, 13);
            this.lblCTECount.TabIndex = 5;
            this.lblCTECount.Text = "0";
            // 
            // lblCTEsFound
            // 
            this.lblCTEsFound.AutoSize = true;
            this.lblCTEsFound.Location = new System.Drawing.Point(978, 46);
            this.lblCTEsFound.Name = "lblCTEsFound";
            this.lblCTEsFound.Size = new System.Drawing.Size(114, 13);
            this.lblCTEsFound.TabIndex = 6;
            this.lblCTEsFound.Text = "Items Found (Product):";
            // 
            // txtSearched
            // 
            this.txtSearched.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.txtSearched.Location = new System.Drawing.Point(75, 431);
            this.txtSearched.Multiline = true;
            this.txtSearched.Name = "txtSearched";
            this.txtSearched.ScrollBars = System.Windows.Forms.ScrollBars.Both;
            this.txtSearched.Size = new System.Drawing.Size(785, 164);
            this.txtSearched.TabIndex = 7;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(376, 44);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(60, 13);
            this.label1.TabIndex = 8;
            this.label1.Text = "File Pattern";
            // 
            // txtDirPattern
            // 
            this.txtDirPattern.Location = new System.Drawing.Point(75, 41);
            this.txtDirPattern.Name = "txtDirPattern";
            this.txtDirPattern.Size = new System.Drawing.Size(249, 20);
            this.txtDirPattern.TabIndex = 9;
            this.txtDirPattern.Text = "Main";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(12, 44);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(57, 13);
            this.label2.TabIndex = 10;
            this.label2.Text = "Dir Pattern";
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(12, 70);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(43, 13);
            this.label3.TabIndex = 11;
            this.label3.Text = "Look In";
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(12, 18);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(42, 13);
            this.label4.TabIndex = 13;
            this.label4.Text = "Reg Ex";
            // 
            // dgvResults
            // 
            this.dgvResults.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.dgvResults.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvResults.Location = new System.Drawing.Point(867, 431);
            this.dgvResults.Name = "dgvResults";
            this.dgvResults.Size = new System.Drawing.Size(291, 164);
            this.dgvResults.TabIndex = 15;
            this.dgvResults.CellDoubleClick += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvResults_CellDoubleClick);
            // 
            // btnClear
            // 
            this.btnClear.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.btnClear.Location = new System.Drawing.Point(75, 601);
            this.btnClear.Name = "btnClear";
            this.btnClear.Size = new System.Drawing.Size(75, 23);
            this.btnClear.TabIndex = 16;
            this.btnClear.Text = "&Clear";
            this.btnClear.UseVisualStyleBackColor = true;
            this.btnClear.Click += new System.EventHandler(this.btnClear_Click);
            // 
            // txtWriteTo
            // 
            this.txtWriteTo.Location = new System.Drawing.Point(75, 94);
            this.txtWriteTo.Name = "txtWriteTo";
            this.txtWriteTo.Size = new System.Drawing.Size(613, 20);
            this.txtWriteTo.TabIndex = 17;
            this.txtWriteTo.Text = "C:\\TFSChecks";
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Location = new System.Drawing.Point(12, 97);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(44, 13);
            this.label5.TabIndex = 18;
            this.label5.Text = "Write to";
            // 
            // btnWriteTo
            // 
            this.btnWriteTo.Location = new System.Drawing.Point(694, 92);
            this.btnWriteTo.Name = "btnWriteTo";
            this.btnWriteTo.Size = new System.Drawing.Size(25, 23);
            this.btnWriteTo.TabIndex = 19;
            this.btnWriteTo.Text = "...";
            this.btnWriteTo.UseVisualStyleBackColor = true;
            this.btnWriteTo.Click += new System.EventHandler(this.btnWriteTo_Click);
            // 
            // chkWrite
            // 
            this.chkWrite.AutoSize = true;
            this.chkWrite.Checked = true;
            this.chkWrite.CheckState = System.Windows.Forms.CheckState.Checked;
            this.chkWrite.Location = new System.Drawing.Point(726, 96);
            this.chkWrite.Name = "chkWrite";
            this.chkWrite.Size = new System.Drawing.Size(57, 17);
            this.chkWrite.TabIndex = 20;
            this.chkWrite.Text = "Write?";
            this.chkWrite.UseVisualStyleBackColor = true;
            // 
            // dgvHits
            // 
            dataGridViewCellStyle2.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(128)))), ((int)(((byte)(255)))), ((int)(((byte)(128)))));
            this.dgvHits.AlternatingRowsDefaultCellStyle = dataGridViewCellStyle2;
            this.dgvHits.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.dgvHits.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvHits.Location = new System.Drawing.Point(75, 121);
            this.dgvHits.Name = "dgvHits";
            this.dgvHits.Size = new System.Drawing.Size(1083, 304);
            this.dgvHits.TabIndex = 21;
            this.dgvHits.CellDoubleClick += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvHits_CellDoubleClick);
            // 
            // label6
            // 
            this.label6.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left)));
            this.label6.AutoSize = true;
            this.label6.Location = new System.Drawing.Point(12, 121);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(37, 13);
            this.label6.TabIndex = 22;
            this.label6.Text = "Found";
            // 
            // label7
            // 
            this.label7.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Left)));
            this.label7.AutoSize = true;
            this.label7.Location = new System.Drawing.Point(12, 431);
            this.label7.Name = "label7";
            this.label7.Size = new System.Drawing.Size(48, 13);
            this.label7.TabIndex = 23;
            this.label7.Text = "Progress";
            // 
            // label8
            // 
            this.label8.AutoSize = true;
            this.label8.Location = new System.Drawing.Point(991, 67);
            this.label8.Name = "label8";
            this.label8.Size = new System.Drawing.Size(101, 13);
            this.label8.TabIndex = 24;
            this.label8.Text = "Items Found (Total):";
            // 
            // lblItemCountTotal
            // 
            this.lblItemCountTotal.AutoSize = true;
            this.lblItemCountTotal.Location = new System.Drawing.Point(1111, 67);
            this.lblItemCountTotal.Name = "lblItemCountTotal";
            this.lblItemCountTotal.Size = new System.Drawing.Size(13, 13);
            this.lblItemCountTotal.TabIndex = 25;
            this.lblItemCountTotal.Text = "0";
            // 
            // cmbRegEx
            // 
            this.cmbRegEx.FormattingEnabled = true;
            this.cmbRegEx.Location = new System.Drawing.Point(75, 15);
            this.cmbRegEx.Name = "cmbRegEx";
            this.cmbRegEx.Size = new System.Drawing.Size(1083, 21);
            this.cmbRegEx.TabIndex = 26;
            // 
            // lblProgess
            // 
            this.lblProgess.Anchor = System.Windows.Forms.AnchorStyles.Bottom;
            this.lblProgess.AutoSize = true;
            this.lblProgess.Location = new System.Drawing.Point(589, 610);
            this.lblProgess.Name = "lblProgess";
            this.lblProgess.Size = new System.Drawing.Size(38, 13);
            this.lblProgess.TabIndex = 27;
            this.lblProgess.Text = "Ready";
            // 
            // frmFiF
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1213, 654);
            this.Controls.Add(this.lblProgess);
            this.Controls.Add(this.cmbRegEx);
            this.Controls.Add(this.lblItemCountTotal);
            this.Controls.Add(this.label8);
            this.Controls.Add(this.label7);
            this.Controls.Add(this.label6);
            this.Controls.Add(this.dgvHits);
            this.Controls.Add(this.chkWrite);
            this.Controls.Add(this.btnWriteTo);
            this.Controls.Add(this.label5);
            this.Controls.Add(this.txtWriteTo);
            this.Controls.Add(this.btnClear);
            this.Controls.Add(this.dgvResults);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.txtDirPattern);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.txtSearched);
            this.Controls.Add(this.lblCTEsFound);
            this.Controls.Add(this.lblCTECount);
            this.Controls.Add(this.btnFind);
            this.Controls.Add(this.btnDirSel);
            this.Controls.Add(this.txtDirectoryPattern);
            this.Controls.Add(this.txtFilePattern);
            this.Name = "frmFiF";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Find In Files";
            ((System.ComponentModel.ISupportInitialize)(this.dgvResults)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.dgvHits)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.TextBox txtFilePattern;
        private System.Windows.Forms.TextBox txtDirectoryPattern;
        private System.Windows.Forms.Button btnDirSel;
        private System.Windows.Forms.Button btnFind;
        private System.Windows.Forms.Label lblCTECount;
        private System.Windows.Forms.Label lblCTEsFound;
        private System.Windows.Forms.TextBox txtSearched;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.TextBox txtDirPattern;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.DataGridView dgvResults;
        private System.Windows.Forms.Button btnClear;
        private System.Windows.Forms.TextBox txtWriteTo;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.Button btnWriteTo;
        private System.Windows.Forms.CheckBox chkWrite;
        private System.Windows.Forms.DataGridView dgvHits;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.Label label7;
        private System.Windows.Forms.Label label8;
        private System.Windows.Forms.Label lblItemCountTotal;
        private System.Windows.Forms.ComboBox cmbRegEx;
        private System.Windows.Forms.Label lblProgess;
    }
}

