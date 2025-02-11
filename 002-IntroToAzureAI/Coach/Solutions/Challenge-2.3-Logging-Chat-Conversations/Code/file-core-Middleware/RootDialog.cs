﻿namespace MiddlewareBot
{
    using System;
    using System.Threading.Tasks;
    using Microsoft.Bot.Builder.Dialogs;
    using Microsoft.Bot.Connector;
    using System.Diagnostics;

#pragma warning disable 1998

    [Serializable]
    public class RootDialog : IDialog<object>
    {
        public async Task StartAsync(IDialogContext context)
        {
            context.Wait(this.MessageReceivedAsync);
        }

        private async Task MessageReceivedAsync(IDialogContext context, IAwaitable<IMessageActivity> result)
        {
            var message = await result;

            await context.PostAsync($"You sent {message.Text} which was {message.Text.Length} characters");

            // Graceful exit when user types exit
            if (message.Text.ToLower().Contains("exit"))
            {
                context.Done(true);
                Debug.WriteLine("Graceful Exit");
                System.Environment.Exit(0);
            }
            context.Wait(this.MessageReceivedAsync);



        }
    }
}
