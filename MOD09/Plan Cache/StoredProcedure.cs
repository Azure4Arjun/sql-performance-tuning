using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Data;
using System.Data.SqlClient;

namespace ExecSP
{
    class ExecSP
    {
        static void Main(string[] args)
        {
            using (var conn = new SqlConnection("Server=(local);DataBase=AdventureWorks2008R2;Integrated Security=SSPI"))
            using (var command = new SqlCommand("usp_Orders", conn) { 
                CommandType = CommandType.StoredProcedure }) {
                    SqlParameter param = new SqlParameter();
                    param = command.Parameters.Add("@CustID", SqlDbType.Int);
                    param.Direction = ParameterDirection.Input;
                    conn.Open();
                        for (int i = 20000; i < 25000; i = i + 1)
                        {
                        param.Value = i;
                        command.ExecuteNonQuery();
                        }
                conn.Close();
                }
             }    
        }
    }

